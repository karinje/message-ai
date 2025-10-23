//
//  ChatListViewModel.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    
    private let firestoreService = FirestoreService()
    private let authService: AuthService
    private var lastMessageTimestamps: [String: Date] = [:]
    private var hasInitializedTimestamps = false
    private var activeConversationId: String?
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func setActiveConversation(id: String?) {
        activeConversationId = id
        NotificationService.shared.setActiveConversation(id: id)
    }
    
    func startListening() {
        guard let userId = authService.currentUser?.id else { return }
        
        firestoreService.listenToConversations(userId: userId) { [weak self] conversations in
            guard let self else { return }
            self.conversations = conversations
            self.handleConversationUpdates(conversations: conversations)
        }
    }
    
    func stopListening() {
        firestoreService.removeConversationListener()
        conversations = []
    }
    
    func createDirectConversation(with user: User) async throws -> Conversation {
        guard let currentUser = authService.currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        return try await firestoreService.createDirectConversation(with: user, currentUser: currentUser)
    }
    
    func createGroupConversation(name: String, participants: [User]) async throws -> Conversation {
        guard let currentUser = authService.currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        return try await firestoreService.createGroupConversation(name: name, participants: participants, currentUser: currentUser)
    }
    
    private func handleConversationUpdates(conversations: [Conversation]) {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        var updatedTimestamps: [String: Date] = [:]
        var newMessages: [(Conversation, Date)] = []
        
        for conversation in conversations {
            guard let convoId = conversation.id, let lastMessageTime = conversation.lastMessageTime else { continue }
            updatedTimestamps[convoId] = lastMessageTime
            
            if let previousTime = lastMessageTimestamps[convoId] {
                if lastMessageTime > previousTime,
                   conversation.lastMessageSenderId != currentUserId,
                   hasInitializedTimestamps,
                   convoId != activeConversationId {
                    newMessages.append((conversation, lastMessageTime))
                }
            }
        }
        
        lastMessageTimestamps = updatedTimestamps
        if !hasInitializedTimestamps {
            hasInitializedTimestamps = true
            return
        }

        for (conversation, _) in newMessages {
            #if targetEnvironment(simulator)
            let name = conversation.displayName(for: currentUserId)
            let body = conversation.lastMessage ?? "New message"
            let userInfo: [AnyHashable: Any] = [
                "conversationId": conversation.id ?? ""
            ]
            NotificationService.shared.presentLocalDebugNotification(title: name, body: body, userInfo: userInfo)
            #endif
        }
    }
}

