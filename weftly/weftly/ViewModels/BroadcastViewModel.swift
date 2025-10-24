//
//  BroadcastViewModel.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class BroadcastViewModel: ObservableObject {
    @Published var broadcastLists: [BroadcastList] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    let authService: AuthService
    private let firestoreService = FirestoreService()
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func startListening() {
        guard let userId = authService.currentUser?.id else { return }
        
        listener = db.collection("users").document(userId).collection("broadcastLists")
            .order(by: "lastUsed", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.broadcastLists = documents.compactMap { doc -> BroadcastList? in
                    try? doc.data(as: BroadcastList.self)
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func createBroadcastList(name: String, recipientIds: [String]) async throws {
        guard let userId = authService.currentUser?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let listId = UUID().uuidString
        var list = BroadcastList(
            name: name,
            recipientIds: recipientIds,
            lastUsed: Date(),
            messageCount: 0
        )
        list.id = listId
        
        try db.collection("users").document(userId).collection("broadcastLists").document(listId)
            .setData(from: list)
    }
    
    func updateBroadcastList(listId: String, name: String?, recipientIds: [String]?) async throws {
        guard let userId = authService.currentUser?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        var updateData: [String: Any] = [:]
        if let name = name {
            updateData["name"] = name
        }
        if let recipientIds = recipientIds {
            updateData["recipientIds"] = recipientIds
        }
        
        try await db.collection("users").document(userId).collection("broadcastLists").document(listId)
            .updateData(updateData)
    }
    
    func deleteBroadcastList(listId: String) async throws {
        guard let userId = authService.currentUser?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        try await db.collection("users").document(userId).collection("broadcastLists").document(listId).delete()
    }
    
    // Send broadcast message
    func sendBroadcastMessage(listId: String, messageText: String, imageUrl: String? = nil) async throws {
        guard let userId = authService.currentUser?.id,
              let currentUser = authService.currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        // Find the broadcast list
        guard let broadcastList = broadcastLists.first(where: { $0.id == listId }) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Broadcast list not found"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Send message to each recipient individually
        for recipientId in broadcastList.recipientIds {
            do {
                // Get or create 1:1 conversation with each recipient
                let conversationId = try await getOrCreateDirectConversation(with: recipientId, currentUser: currentUser)
                
                // Send message to that conversation
                _ = try await firestoreService.sendMessage(
                    conversationId: conversationId,
                    senderId: userId,
                    senderName: currentUser.displayName,
                    text: messageText,
                    mediaUrl: imageUrl
                )
            } catch {
                print("Error sending broadcast message to \(recipientId): \(error.localizedDescription)")
                // Continue with other recipients even if one fails
            }
        }
        
        // Update broadcast list lastUsed and messageCount
        try await db.collection("users").document(userId).collection("broadcastLists").document(listId)
            .updateData([
                "lastUsed": FieldValue.serverTimestamp(),
                "messageCount": FieldValue.increment(Int64(1))
            ])
    }
    
    private func getOrCreateDirectConversation(with recipientId: String, currentUser: User) async throws -> String {
        guard let userId = currentUser.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user ID"])
        }
        
        // Check if conversation already exists
        let existingConversations = try await db.collection("conversations")
            .whereField("type", isEqualTo: "direct")
            .whereField("participants", arrayContains: userId)
            .getDocuments()
        
        // Find conversation with this specific recipient
        for doc in existingConversations.documents {
            let conv = try? doc.data(as: Conversation.self)
            if conv?.participants.contains(recipientId) == true {
                return doc.documentID
            }
        }
        
        // Create new conversation if doesn't exist
        let newConvRef = db.collection("conversations").document()
        let recipientDoc = try await db.collection("users").document(recipientId).getDocument()
        let recipient = try recipientDoc.data(as: User.self)
        
        let conversation = Conversation(
            id: newConvRef.documentID,
            type: .direct,
            participants: [userId, recipientId],
            participantNames: [
                userId: currentUser.displayName,
                recipientId: recipient.displayName
            ],
            participantProfileUrls: [
                userId: currentUser.profilePictureUrl ?? "",
                recipientId: recipient.profilePictureUrl ?? ""
            ],
            unreadCount: [userId: 0, recipientId: 0]
        )
        
        try newConvRef.setData(from: conversation)
        return newConvRef.documentID
    }
}

