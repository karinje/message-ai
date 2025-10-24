//
//  ChatViewModel.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var isLoading = false
    @Published var pendingImageData: Data?
    @Published var currentConversation: Conversation
    
    private let firestoreService = FirestoreService()
    private let storageService = StorageService()
    private let authService: AuthService
    private let networkMonitor: NetworkMonitor
    private let modelContext: ModelContext
    
    private var typingTimer: Timer?
    
    init(conversation: Conversation, authService: AuthService, networkMonitor: NetworkMonitor, modelContext: ModelContext) {
        self.currentConversation = conversation
        self.authService = authService
        self.networkMonitor = networkMonitor
        self.modelContext = modelContext
    }
    
    func startListening() {
        guard let conversationId = currentConversation.id else { return }
        
        // Listen to messages
        firestoreService.listenToMessages(conversationId: conversationId) { [weak self] messages in
            self?.messages = messages
            self?.markMessagesAsRead()
        }
        
        // Listen to conversation updates (for typing indicators)
        firestoreService.listenToConversation(conversationId: conversationId) { [weak self] conversation in
            if let conversation = conversation {
                self?.currentConversation = conversation
            }
        }
    }
    
    func stopListening() {
        guard let conversationId = currentConversation.id else { return }
        firestoreService.removeMessageListener(conversationId: conversationId)
        firestoreService.removeConversationListener(conversationId: conversationId)
        updateTypingStatus(isTyping: false)
    }
    
    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingImageData != nil else { return }
        guard let conversationId = currentConversation.id else { return }
        guard let currentUser = authService.currentUser else { return }
        guard let userId = currentUser.id else { return }
        
        let text = messageText
        let imageData = pendingImageData
        messageText = ""
        pendingImageData = nil
    
        let message = Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: userId,
            senderName: currentUser.displayName,
            senderProfileUrl: currentUser.profilePictureUrl,
            text: text,
            timestamp: Date(),
            status: .sending,
            readBy: [userId],
            localImageData: imageData
        )
        
        // Optimistic UI - add message immediately
        messages.append(message)
        
        // Try to send
        Task {
            if networkMonitor.isConnected {
                do {
                    var messageToSend = message

                    if let imageData = imageData, let image = UIImage(data: imageData) {
                        let upload = try await storageService.uploadImage(image, path: "message_images/\(conversationId)/\(UUID().uuidString).jpg")
                        messageToSend.imageUrl = upload.url
                        messageToSend.localImageData = nil
                    }
                    
                    let sentMessage = try await firestoreService.sendMessage(messageToSend)
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
        guard let currentImageData = image.jpegData(compressionQuality: 0.7) else { return }
        pendingImageData = currentImageData
    }
    
    func updateTypingStatus(isTyping: Bool) {
        guard let conversationId = currentConversation.id else { return }
        guard let userId = authService.currentUser?.id else { return }
        
        Task {
            do {
                try await firestoreService.updateTypingStatus(conversationId: conversationId, userId: userId, isTyping: isTyping)
                print("🔤 Typing status updated: \(isTyping) for user \(userId)")
            } catch {
                print("❌ Error updating typing status: \(error.localizedDescription)")
            }
        }
    }
    
    func handleTextChange() {
        typingTimer?.invalidate()
        
        if !messageText.isEmpty {
            updateTypingStatus(isTyping: true)
            
            typingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateTypingStatus(isTyping: false)
                }
            }
        } else {
            updateTypingStatus(isTyping: false)
        }
    }
    
    private func markMessagesAsRead() {
        guard let conversationId = currentConversation.id else { return }
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
            predicate: #Predicate { $0.conversationId == currentConversation.id ?? "" }
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
        let typingUserIds = currentConversation.typingUsers.filter { $0 != authService.currentUser?.id }
        guard !typingUserIds.isEmpty else { return nil }
        
        print("🔤 Typing users detected: \(typingUserIds)")
        
        let names = typingUserIds.compactMap { currentConversation.participantNames[$0] }
        if names.count == 1 {
            return "\(names[0]) is typing..."
        } else if names.count == 2 {
            return "\(names[0]) and \(names[1]) are typing..."
        } else {
            return "Multiple people are typing..."
        }
    }
}

