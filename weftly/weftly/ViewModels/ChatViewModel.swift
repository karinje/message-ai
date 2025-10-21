//
//  ChatViewModel.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var isLoading = false
    
    let conversation: Conversation
    private let firestoreService = FirestoreService()
    private let storageService = StorageService()
    private let authService: AuthService
    private let networkMonitor: NetworkMonitor
    private let modelContext: ModelContext
    
    private var typingTimer: Timer?
    
    init(conversation: Conversation, authService: AuthService, networkMonitor: NetworkMonitor, modelContext: ModelContext) {
        self.conversation = conversation
        self.authService = authService
        self.networkMonitor = networkMonitor
        self.modelContext = modelContext
    }
    
    func startListening() {
        guard let conversationId = conversation.id else { return }
        
        firestoreService.listenToMessages(conversationId: conversationId) { [weak self] messages in
            self?.messages = messages
            self?.markMessagesAsRead()
        }
    }
    
    func stopListening() {
        guard let conversationId = conversation.id else { return }
        firestoreService.removeMessageListener(conversationId: conversationId)
        updateTypingStatus(isTyping: false)
    }
    
    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let conversationId = conversation.id else { return }
        guard let currentUser = authService.currentUser else { return }
        guard let userId = currentUser.id else { return }
        
        let text = messageText
        messageText = ""
        
        let message = Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: userId,
            senderName: currentUser.displayName,
            senderProfileUrl: currentUser.profilePictureUrl,
            text: text,
            timestamp: Date(),
            status: .sending,
            readBy: [userId]
        )
        
        // Optimistic UI - add message immediately
        messages.append(message)
        
        // Try to send
        Task {
            if networkMonitor.isConnected {
                do {
                    let sentMessage = try await firestoreService.sendMessage(message)
                    if let index = messages.firstIndex(where: { $0.id == message.id }) {
                        messages[index] = sentMessage
                    }
                } catch {
                    print("Error sending message: \(error.localizedDescription)")
                    // Store in pending queue
                    savePendingMessage(message)
                    if let index = messages.firstIndex(where: { $0.id == message.id }) {
                        messages[index].status = .failed
                    }
                }
            } else {
                // Store in pending queue for later
                savePendingMessage(message)
            }
        }
    }
    
    func sendImage(_ image: UIImage) {
        guard let conversationId = conversation.id else { return }
        guard let currentUser = authService.currentUser else { return }
        guard let userId = currentUser.id else { return }
        
        Task {
            do {
                let imageUrl = try await storageService.uploadMessageImage(image, conversationId: conversationId)
                
                let message = Message(
                    id: UUID().uuidString,
                    conversationId: conversationId,
                    senderId: userId,
                    senderName: currentUser.displayName,
                    senderProfileUrl: currentUser.profilePictureUrl,
                    text: "📷 Image",
                    imageUrl: imageUrl,
                    timestamp: Date(),
                    status: .sent,
                    readBy: [userId]
                )
                
                _ = try await firestoreService.sendMessage(message)
            } catch {
                print("Error sending image: \(error.localizedDescription)")
            }
        }
    }
    
    func updateTypingStatus(isTyping: Bool) {
        guard let conversationId = conversation.id else { return }
        guard let userId = authService.currentUser?.id else { return }
        
        Task {
            try? await firestoreService.updateTypingStatus(conversationId: conversationId, userId: userId, isTyping: isTyping)
        }
    }
    
    func handleTextChange() {
        typingTimer?.invalidate()
        
        if !messageText.isEmpty {
            updateTypingStatus(isTyping: true)
            
            typingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                self?.updateTypingStatus(isTyping: false)
            }
        } else {
            updateTypingStatus(isTyping: false)
        }
    }
    
    private func markMessagesAsRead() {
        guard let conversationId = conversation.id else { return }
        guard let userId = authService.currentUser?.id else { return }
        
        Task {
            for message in messages where !message.readBy.contains(userId) && message.senderId != userId {
                if let messageId = message.id {
                    try? await firestoreService.markMessageAsRead(messageId: messageId, conversationId: conversationId, userId: userId)
                }
            }
        }
    }
    
    private func savePendingMessage(_ message: Message) {
        let pendingMessage = PendingMessage(
            id: message.id ?? UUID().uuidString,
            conversationId: message.conversationId,
            text: message.text
        )
        modelContext.insert(pendingMessage)
        try? modelContext.save()
    }
    
    func retryPendingMessages() {
        let descriptor = FetchDescriptor<PendingMessage>(
            predicate: #Predicate { $0.conversationId == conversation.id ?? "" }
        )
        
        guard let pendingMessages = try? modelContext.fetch(descriptor) else { return }
        
        for pending in pendingMessages {
            guard let currentUser = authService.currentUser, let userId = currentUser.id else { continue }
            
            let message = Message(
                id: pending.id,
                conversationId: pending.conversationId,
                senderId: userId,
                senderName: currentUser.displayName,
                senderProfileUrl: currentUser.profilePictureUrl,
                text: pending.text,
                timestamp: pending.timestamp,
                status: .sending,
                readBy: [userId]
            )
            
            Task {
                do {
                    _ = try await firestoreService.sendMessage(message)
                    modelContext.delete(pending)
                    try? modelContext.save()
                } catch {
                    print("Error retrying message: \(error.localizedDescription)")
                }
            }
        }
    }
    
    var typingUsersText: String? {
        let typingUserIds = conversation.typingUsers.filter { $0 != authService.currentUser?.id }
        guard !typingUserIds.isEmpty else { return nil }
        
        let names = typingUserIds.compactMap { conversation.participantNames[$0] }
        if names.count == 1 {
            return "\(names[0]) is typing..."
        } else if names.count == 2 {
            return "\(names[0]) and \(names[1]) are typing..."
        } else {
            return "Multiple people are typing..."
        }
    }
}

