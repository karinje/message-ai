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
        
        // Update conversation's last message
        try await db.collection("conversations")
            .document(messageToSend.conversationId)
            .updateData([
                "lastMessage": messageToSend.text,
                "lastMessageSenderId": messageToSend.senderId,
                "lastMessageTime": Timestamp(date: messageToSend.timestamp)
            ])
        
        return messageToSend
    }
    
    func listenToMessages(conversationId: String, completion: @escaping ([Message]) -> Void) {
        let listener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                let messages = documents.compactMap { doc -> Message? in
                    var msg = try? doc.data(as: Message.self)
                    if msg?.id == nil { msg?.id = doc.documentID }
                    return msg
                }
                
                completion(messages)
            }
        
        messageListeners[conversationId] = listener
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
    
    deinit {
        conversationListeners.values.forEach { $0.remove() }
        messageListeners.values.forEach { $0.remove() }
    }
}

