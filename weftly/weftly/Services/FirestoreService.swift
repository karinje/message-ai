//
//  FirestoreService.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    private var conversationListeners: [String: ListenerRegistration] = [:]
    private var messageListeners: [String: ListenerRegistration] = [:]
    
    // MARK: - Conversations
    
    func createDirectConversation(with user: User, currentUser: User) async throws -> Conversation {
        guard let currentUserId = currentUser.id, let otherUserId = user.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user IDs"])
        }
        
        // Check if conversation already exists
        if let existingConv = try await getExistingDirectConversation(userId1: currentUserId, userId2: otherUserId) {
            print("🔁 Reusing existing direct conversation: \(existingConv.id ?? "unknown")")
            return existingConv
        }
        
        let conversation = Conversation(
            type: .direct,
            participants: [currentUserId, otherUserId],
            participantNames: [
                currentUserId: currentUser.displayName,
                otherUserId: user.displayName
            ],
            participantProfileUrls: [
                currentUserId: currentUser.profilePictureUrl ?? "",
                otherUserId: user.profilePictureUrl ?? ""
            ]
        )
        
        let conversationData: [String: Any] = [
            "type": conversation.type.rawValue,
            "participants": conversation.participants,
            "participantNames": conversation.participantNames,
            "participantProfileUrls": conversation.participantProfileUrls,
            "unreadCount": [:],
            "typingUsers": []
        ]
        
        print("📝 Creating conversation with data: \(conversationData)")
        
        let docRef = try await db.collection("conversations").addDocument(data: conversationData)
        
        var newConv = conversation
        newConv.id = docRef.documentID
        print("✅ Conversation created with ID: \(docRef.documentID)")
        return newConv
    }
    
    func createGroupConversation(name: String, participants: [User], currentUser: User) async throws -> Conversation {
        guard let currentUserId = currentUser.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid current user ID"])
        }
        
        var participantIds = participants.compactMap { $0.id }
        if !participantIds.contains(currentUserId) {
            participantIds.append(currentUserId)
        }
        participantIds.sort()
        
        // Check if a group with same members already exists
        if let existingGroup = try await getExistingGroupConversation(participantIds: participantIds) {
            print("🔁 Reusing existing group conversation: \(existingGroup.id ?? "unknown")")
            return existingGroup
        }
        
        var participantNames: [String: String] = [currentUserId: currentUser.displayName]
        var participantProfileUrls: [String: String] = [currentUserId: currentUser.profilePictureUrl ?? ""]
        
        for participant in participants {
            if let id = participant.id {
                participantNames[id] = participant.displayName
                participantProfileUrls[id] = participant.profilePictureUrl ?? ""
            }
        }
        
        let conversation = Conversation(
            type: .group,
            participants: participantIds,
            participantNames: participantNames,
            participantProfileUrls: participantProfileUrls,
            groupName: name
        )
        
        let conversationData: [String: Any] = [
            "type": conversation.type.rawValue,
            "participants": conversation.participants,
            "participantNames": conversation.participantNames,
            "participantProfileUrls": conversation.participantProfileUrls,
            "groupName": name,
            "unreadCount": [:],
            "typingUsers": []
        ]
        
        print("📝 Creating group conversation with data: \(conversationData)")
        
        let docRef = db.collection("conversations").document()
        try await docRef.setData(conversationData)
        
        var newConv = conversation
        newConv.id = docRef.documentID
        print("✅ Group conversation created with ID: \(docRef.documentID)")
        return newConv
    }
    
    func listenToConversations(userId: String, completion: @escaping ([Conversation]) -> Void) {
        let listener = db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching conversations: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                print("💬 Found \(documents.count) conversations for user")
                
                let conversations = documents.compactMap { doc -> Conversation? in
                    var conv = try? doc.data(as: Conversation.self)
                    if conv?.id == nil { conv?.id = doc.documentID }
                    print("💬 Conversation: \(doc.documentID) - participants: \(conv?.participants ?? [])")
                    
                    // Filter out conversations with empty participants (broken data)
                    if conv?.participants.isEmpty == true {
                        print("⚠️ Skipping conversation with empty participants")
                        return nil
                    }
                    
                    return conv
                }
                .sorted { ($0.lastMessageTime ?? Date.distantPast) > ($1.lastMessageTime ?? Date.distantPast) }
                
                print("✅ Returning \(conversations.count) valid conversations")
                completion(conversations)
            }
        
        conversationListeners["main"] = listener
    }
    
    func listenToConversation(conversationId: String, completion: @escaping (Conversation?) -> Void) {
        let listener = db.collection("conversations")
            .document(conversationId)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("❌ Error fetching conversation: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                var conversation = try? snapshot.data(as: Conversation.self)
                if conversation?.id == nil {
                    conversation?.id = snapshot.documentID
                }
                
                if let typingUsers = conversation?.typingUsers {
                    print("🔤 Conversation updated - typing users: \(typingUsers)")
                }
                
                completion(conversation)
            }
        
        conversationListeners["detail_\(conversationId)"] = listener
    }
    
    func removeConversationListener(conversationId: String? = nil) {
        if let conversationId = conversationId {
            // Remove specific conversation listener
            conversationListeners["detail_\(conversationId)"]?.remove()
            conversationListeners.removeValue(forKey: "detail_\(conversationId)")
        } else {
            // Remove main conversations list listener
            conversationListeners["main"]?.remove()
            conversationListeners.removeValue(forKey: "main")
        }
    }
    
    private func getExistingDirectConversation(userId1: String, userId2: String) async throws -> Conversation? {
        let snapshot = try await db.collection("conversations")
            .whereField("type", isEqualTo: "direct")
            .whereField("participants", arrayContains: userId1)
            .getDocuments()
        
        for document in snapshot.documents {
            if var conversation = try? document.data(as: Conversation.self),
               conversation.participants.contains(userId2) {
                if conversation.id == nil { conversation.id = document.documentID }
                return conversation
            }
        }
        
        return nil
    }
    
    private func getExistingGroupConversation(participantIds: [String]) async throws -> Conversation? {
        guard let currentUserId = participantIds.first else { return nil }
        
        let snapshot = try await db.collection("conversations")
            .whereField("type", isEqualTo: "group")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments()
        
        for document in snapshot.documents {
            if var conversation = try? document.data(as: Conversation.self) {
                if conversation.id == nil { conversation.id = document.documentID }
                let existingParticipants = conversation.participants.sorted()
                if existingParticipants == participantIds {
                    return conversation
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Messages
    
    func sendMessage(_ message: Message) async throws -> Message {
        guard let conversationId = message.id ?? UUID().uuidString as String? else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid message ID"])
        }
        
        var messageToSend = message
        messageToSend.id = conversationId
        messageToSend.status = .sent
        
        var messageData: [String: Any] = [
            "conversationId": messageToSend.conversationId,
            "senderId": messageToSend.senderId,
            "senderName": messageToSend.senderName,
            "text": messageToSend.text,
            "timestamp": Timestamp(date: messageToSend.timestamp),
            "status": messageToSend.status.rawValue,
            "readBy": messageToSend.readBy
        ]
        
        // Only include optional fields if they have values
        if let profileUrl = messageToSend.senderProfileUrl, !profileUrl.isEmpty {
            messageData["senderProfileUrl"] = profileUrl
        }
        if let imageUrl = messageToSend.imageUrl, !imageUrl.isEmpty {
            messageData["imageUrl"] = imageUrl
        }
        
        try await db.collection("conversations")
            .document(messageToSend.conversationId)
            .collection("messages")
            .document(conversationId)
            .setData(messageData)
        
        // Get conversation to find all participants
        let conversationDoc = try await db.collection("conversations")
            .document(messageToSend.conversationId)
            .getDocument()
        
        let conversation = try? conversationDoc.data(as: Conversation.self)
        let participants = conversation?.participants ?? []
        
        // Build unreadCount updates for all other participants
        var unreadUpdates: [String: Any] = [:]
        for participantId in participants where participantId != messageToSend.senderId {
            unreadUpdates["unreadCount.\(participantId)"] = FieldValue.increment(Int64(1))
        }
        
        // Update conversation's last message, timestamp, unread counts
        var updates: [String: Any] = [
            "lastMessage": messageToSend.text,
            "lastMessageSenderId": messageToSend.senderId,
            "lastMessageTime": FieldValue.serverTimestamp()
        ]
        updates.merge(unreadUpdates) { _, new in new }
        
        try await db.collection("conversations")
            .document(messageToSend.conversationId)
            .updateData(updates)
        
        return messageToSend
    }
    
    // Convenience method for sending messages with parameters
    func sendMessage(conversationId: String, senderId: String, senderName: String, text: String, mediaUrl: String? = nil) async throws -> Message {
        let messageId = UUID().uuidString
        let message = Message(
            id: messageId,
            conversationId: conversationId,
            senderId: senderId,
            senderName: senderName,
            senderProfileUrl: nil,
            text: text,
            imageUrl: mediaUrl,
            timestamp: Date(),
            status: .sent,
            readBy: [senderId]
        )
        
        return try await sendMessage(message)
    }
    
    func listenToMessages(conversationId: String, completion: @escaping ([Message]) -> Void) {
        print("👂 Setting up Firestore message listener for conversation: \(conversationId)")
        
        let listener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error in message listener: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("⚠️ No snapshot")
                    return
                }
                
                // ✅ OPTIMIZED: Only process CHANGES (not all documents)
                let changes = snapshot.documentChanges
                print("📬 Message listener fired - \(changes.count) changes (not \(snapshot.documents.count) total)")
                
                var changedMessages: [Message] = []
                
                for change in changes {
                    switch change.type {
                    case .added:
                        // New message arrived (or initial load)
                        if var msg = try? change.document.data(as: Message.self) {
                            if msg.id == nil { msg.id = change.document.documentID }
                            changedMessages.append(msg)
                            print("➕ Added: \(msg.id ?? "no-id")")
                        }
                        
                    case .modified:
                        // Message updated (status change, read receipt, etc)
                        if var msg = try? change.document.data(as: Message.self) {
                            if msg.id == nil { msg.id = change.document.documentID }
                            changedMessages.append(msg)
                            print("✏️ Modified: \(msg.id ?? "no-id")")
                        }
                        
                    case .removed:
                        // Message deleted from Firestore (future: admin delete)
                        print("🗑️ Removed from Firestore: \(change.document.documentID)")
                        // Don't add to changedMessages - it's deleted
                    }
                }
                
                if !changedMessages.isEmpty {
                    print("✉️ Sending \(changedMessages.count) changed messages to cache")
                    completion(changedMessages)
                } else {
                    print("⏭️ No changes to process")
                }
            }
        
        messageListeners[conversationId] = listener
        print("✅ Listener attached and stored for conversation: \(conversationId)")
    }
    
    func removeMessageListener(conversationId: String) {
        messageListeners[conversationId]?.remove()
        messageListeners.removeValue(forKey: conversationId)
    }
    
    func markMessageAsRead(messageId: String, conversationId: String, userId: String) async throws {
        try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .updateData([
                "readBy": FieldValue.arrayUnion([userId]),
                "status": MessageStatus.read.rawValue
            ])
    }
    
    func updateLastReadTime(conversationId: String, userId: String) async throws {
        try await db.collection("conversations")
            .document(conversationId)
            .updateData([
                "lastReadTime.\(userId)": FieldValue.serverTimestamp(), // Use server timestamp for timezone safety
                "unreadCount.\(userId)": 0 // Reset counter to 0
            ])
    }
    
    func updateTypingStatus(conversationId: String, userId: String, isTyping: Bool) async throws {
        if isTyping {
            try await db.collection("conversations")
                .document(conversationId)
                .updateData([
                    "typingUsers": FieldValue.arrayUnion([userId])
                ])
        } else {
            try await db.collection("conversations")
                .document(conversationId)
                .updateData([
                    "typingUsers": FieldValue.arrayRemove([userId])
                ])
        }
    }
    
    // MARK: - Users
    
    func searchUsers(query: String) async throws -> [User] {
        // Fetch all users and filter locally for case-insensitive search
        print("🔍 Searching for: \(query)")
        
        let snapshot = try await db.collection("users")
            .limit(to: 100)
            .getDocuments()
        
        print("📊 Found \(snapshot.documents.count) total users in database")
        
        let lowercaseQuery = query.lowercased()
        
        let results = snapshot.documents.compactMap { doc -> User? in
            guard var user = try? doc.data(as: User.self) else {
                print("⚠️ Failed to decode user from document: \(doc.documentID)")
                return nil
            }
            // Ensure id is populated from documentID
            if user.id == nil { user.id = doc.documentID }
            print("👤 Checking user: \(user.displayName) (\(user.email))")
            if user.displayName.lowercased().contains(lowercaseQuery) || 
               user.email.lowercased().contains(lowercaseQuery) {
                print("✅ Match found: \(user.displayName)")
                return user
            }
            return nil
        }
        
        print("🎯 Returning \(results.count) matching users")
        return results
    }
    
    func getUser(userId: String) async throws -> User? {
        let document = try await db.collection("users").document(userId).getDocument()
        return try? document.data(as: User.self)
    }
    
    // MARK: - AI Features
    
    func getExtractedEvents(conversationId: String, currentUserId: String? = nil) async throws -> [ExtractedEvent] {
        let snapshot = try await db.collection("conversations")
            .document(conversationId)
            .collection("extractedEvents")
            .order(by: "date", descending: false)
            .getDocuments()
        
        print("📥 Fetching extracted events for conversation: \(conversationId)")
        print("📦 Found \(snapshot.documents.count) event documents")
        
        let allEvents = snapshot.documents.compactMap { doc -> ExtractedEvent? in
            print("🔍 Document \(doc.documentID) data: \(doc.data())")
            do {
                let event = try doc.data(as: ExtractedEvent.self)
                print("✅ Decoded event: \(event.title) at \(event.date)")
                return event
            } catch {
                print("❌ Failed to decode event: \(error)")
                return nil
            }
        }
        
        // Filter out events dismissed by current user
        if let userId = currentUserId {
            let visibleEvents = allEvents.filter { !$0.isDismissedBy(userId: userId) }
            print("📊 Visible events after filtering: \(visibleEvents.count)")
            return visibleEvents
        }
        
        return allEvents
    }
    
    func updateMessagePriority(
        messageId: String,
        conversationId: String,
        priority: String,
        reason: String,
        confidence: Double
    ) async throws {
        try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .updateData([
                "priority": priority,
                "priorityReason": reason,
                "priorityConfidence": confidence
            ])
    }
    
    func getUserDeadlines(userId: String) async throws -> [Deadline] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("deadlines")
            .order(by: "dueDate", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Deadline.self)
        }
    }
    
    func getDecisions(conversationId: String) async throws -> [AIDecision] {
        let snapshot = try await db.collection("conversations")
            .document(conversationId)
            .collection("decisions")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: AIDecision.self)
        }
    }
    
    func getRSVPs(conversationId: String) async throws -> [RSVPResponse] {
        let snapshot = try await db.collection("conversations")
            .document(conversationId)
            .collection("rsvps")
            .order(by: "lastUpdated", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: RSVPResponse.self)
        }
    }
    
    // MARK: - Priority Messages
    
    /// Fetch urgent/important messages from the last 48 hours across all conversations
    func getPriorityMessages(conversationIds: [String], currentUserId: String) async throws -> [PriorityMessage] {
        guard !conversationIds.isEmpty else {
            print("⚠️ No conversation IDs provided for priority messages")
            return []
        }
        
        print("🔍 Fetching priority messages from \(conversationIds.count) conversations")
        
        // Get messages from last 48 hours only
        let cutoffDate = Calendar.current.date(byAdding: .hour, value: -48, to: Date()) ?? Date()
        print("📅 Cutoff date: \(cutoffDate)")
        
        var allPriorityMessages: [PriorityMessage] = []
        
        for conversationId in conversationIds {
            print("🔍 Checking conversation: \(conversationId)")
            
            let snapshot = try await db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .whereField("timestamp", isGreaterThan: Timestamp(date: cutoffDate))
                .whereField("priority", in: ["urgent", "important"])
                .order(by: "timestamp", descending: true)
                .limit(to: 20)
                .getDocuments()
            
            print("📦 Found \(snapshot.documents.count) messages with priority field in \(conversationId)")
            
            let messages = snapshot.documents.compactMap { doc -> PriorityMessage? in
                let data = doc.data()
                print("📄 Document \(doc.documentID): \(data)")
                
                guard let text = data["text"] as? String,
                      let senderId = data["senderId"] as? String,
                      let senderName = data["senderName"] as? String,
                      let priority = data["priority"] as? String,
                      let priorityReason = data["priorityReason"] as? String,
                      let priorityConfidence = data["priorityConfidence"] as? Double,
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                    print("❌ Failed to decode priority message from \(doc.documentID)")
                    print("   - text: \(data["text"] != nil)")
                    print("   - senderId: \(data["senderId"] != nil)")
                    print("   - senderName: \(data["senderName"] != nil)")
                    print("   - priority: \(data["priority"] != nil)")
                    print("   - priorityReason: \(data["priorityReason"] != nil)")
                    print("   - priorityConfidence: \(data["priorityConfidence"] != nil)")
                    print("   - timestamp: \(data["timestamp"] != nil)")
                    return nil
                }
                
                print("✅ Decoded priority message: \(priority) - \(text.prefix(50))")
                
                return PriorityMessage(
                    id: doc.documentID,
                    conversationId: conversationId,
                    senderId: senderId,
                    senderName: senderName,
                    text: text,
                    timestamp: timestamp,
                    priority: priority,
                    priorityReason: priorityReason,
                    priorityConfidence: priorityConfidence
                )
            }
            
            allPriorityMessages.append(contentsOf: messages)
        }
        
        print("✅ Total priority messages found: \(allPriorityMessages.count)")
        
        // Filter out messages dismissed by current user
        let visibleMessages = allPriorityMessages.filter { !$0.isDismissedBy(userId: currentUserId) }
        print("📊 Visible messages after filtering: \(visibleMessages.count)")
        
        // Sort by timestamp (most recent first)
        return visibleMessages.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Dismiss a priority message for the current user
    func dismissPriorityMessage(messageId: String, conversationId: String, userId: String) async throws {
        let docRef = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
        
        try await docRef.updateData([
            "dismissedBy": FieldValue.arrayUnion([userId])
        ])
        
        print("✅ Priority message dismissed: \(messageId)")
    }
    
    /// Dismiss a calendar event for the current user
    func dismissEvent(eventId: String, conversationId: String, userId: String) async throws {
        let docRef = db.collection("conversations")
            .document(conversationId)
            .collection("extractedEvents")
            .document(eventId)
        
        try await docRef.updateData([
            "dismissedBy": FieldValue.arrayUnion([userId])
        ])
        
        print("✅ Event dismissed: \(eventId)")
    }
    
    deinit {
        conversationListeners.values.forEach { $0.remove() }
        messageListeners.values.forEach { $0.remove() }
    }
}

