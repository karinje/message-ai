//
//  ChatListViewModel.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    
    private let firestoreService = FirestoreService()
    private let authService: AuthService
    private var modelContext: ModelContext?
    private var lastMessageTimestamps: [String: Date] = [:]
    private var hasInitializedTimestamps = false
    private var activeConversationId: String?
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func setActiveConversation(id: String?) {
        activeConversationId = id
        NotificationService.shared.setActiveConversation(id: id)
    }
    
    func getUnreadCount(for conversation: Conversation) -> Int {
        guard let context = modelContext,
              let conversationId = conversation.id,
              let currentUserId = authService.currentUser?.id else {
            return 0
        }
        
        // Calculate unread from cache (100% local)
        // Background sync keeps cache updated
        do {
            return try MessageCacheService.shared.calculateUnreadCount(
                for: conversationId,
                currentUserId: currentUserId,
                in: context
            )
        } catch {
            print("❌ Error calculating unread count: \(error)")
            return 0
        }
    }
    
    func startListening() {
        guard let userId = authService.currentUser?.id else {
            print("❌ ChatListViewModel: No user ID, can't start listening")
            return
        }
        
        print("👂 ChatListViewModel: Starting to listen for conversations for user: \(userId)")
        
        firestoreService.listenToConversations(userId: userId) { [weak self] conversations in
            guard let self else { return }
            print("📨 ChatListViewModel: Received \(conversations.count) conversations from Firestore")
            for conv in conversations {
                print("  - Conv: \(conv.id ?? "no-id"), type: \(conv.type), participants: \(conv.participants.count)")
            }
            self.conversations = conversations
            self.handleConversationUpdates(conversations: conversations)
            
            // Background sync for unread counters (optimized - skips unchanged messages)
            self.syncMessagesToCache(for: conversations)
        }
    }
    
    private func syncMessagesToCache(for conversations: [Conversation]) {
        guard let context = modelContext else { return }
        
        for conversation in conversations {
            guard let conversationId = conversation.id else { continue }
            
            // Lightweight background sync: only listens, doesn't re-write unchanged messages
            firestoreService.listenToMessages(conversationId: conversationId) { [weak self] messages in
                guard let self = self else { return }
                
                // Save to cache (optimized: skips unchanged messages automatically)
                Task { @MainActor in
                    do {
                        try MessageCacheService.shared.saveMessages(messages, in: context)
                        
                        // CRITICAL: Update conversation's lastMessage immediately (don't wait for Firestore)
                        // This prevents the 1-second delay in message preview
                        if let lastMessage = messages.last,
                           let index = self.conversations.firstIndex(where: { $0.id == conversationId }) {
                            self.conversations[index].lastMessage = lastMessage.text
                            self.conversations[index].lastMessageTime = lastMessage.timestamp
                            self.conversations[index].lastMessageSenderId = lastMessage.senderId
                            print("⚡️ Updated conversation preview immediately: \(lastMessage.text.prefix(20))...")
                        }
                        
                        // Refresh UI
                        self.objectWillChange.send()
                    } catch {
                        print("❌ Error syncing messages: \(error)")
                    }
                }
            }
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

