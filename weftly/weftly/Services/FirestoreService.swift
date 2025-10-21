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
        let existingConv = try await getExistingDirectConversation(userId1: currentUserId, userId2: otherUserId)
        if let existing = existingConv {
            return existing
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
        
        let docRef = try await db.collection("conversations").addDocument(data: [
            "type": conversation.type.rawValue,
            "participants": conversation.participants,
            "participantNames": conversation.participantNames,
            "participantProfileUrls": conversation.participantProfileUrls,
            "unreadCount": [:]
        ])
        
        var newConv = conversation
        newConv.id = docRef.documentID
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
        
        let docRef = try await db.collection("conversations").addDocument(data: [
            "type": conversation.type.rawValue,
            "participants": conversation.participants,
            "participantNames": conversation.participantNames,
            "participantProfileUrls": conversation.participantProfileUrls,
            "groupName": name,
            "unreadCount": [:]
        ])
        
        var newConv = conversation
        newConv.id = docRef.documentID
        return newConv
    }
    
    func listenToConversations(userId: String, completion: @escaping ([Conversation]) -> Void) {
        let listener = db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastMessageTime", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching conversations: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                let conversations = documents.compactMap { doc -> Conversation? in
                    try? doc.data(as: Conversation.self)
                }
                
                completion(conversations)
            }
        
        conversationListeners["main"] = listener
    }
    
    func removeConversationListener() {
        conversationListeners["main"]?.remove()
        conversationListeners.removeValue(forKey: "main")
    }
    
    private func getExistingDirectConversation(userId1: String, userId2: String) async throws -> Conversation? {
        let snapshot = try await db.collection("conversations")
            .whereField("type", isEqualTo: "direct")
            .whereField("participants", arrayContains: userId1)
            .getDocuments()
        
        for document in snapshot.documents {
            if let conversation = try? document.data(as: Conversation.self),
               conversation.participants.contains(userId2) {
                return conversation
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
        
        let messageData: [String: Any] = [
            "conversationId": messageToSend.conversationId,
            "senderId": messageToSend.senderId,
            "senderName": messageToSend.senderName,
            "senderProfileUrl": messageToSend.senderProfileUrl ?? "",
            "text": messageToSend.text,
            "imageUrl": messageToSend.imageUrl ?? "",
            "timestamp": Timestamp(date: messageToSend.timestamp),
            "status": messageToSend.status.rawValue,
            "readBy": messageToSend.readBy
        ]
        
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
                    try? doc.data(as: Message.self)
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
        let snapshot = try await db.collection("users")
            .whereField("displayName", isGreaterThanOrEqualTo: query)
            .whereField("displayName", isLessThan: query + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: User.self)
        }
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

