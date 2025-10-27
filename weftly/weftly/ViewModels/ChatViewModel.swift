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
    private var cancellables = Set<AnyCancellable>()
    
    init(conversation: Conversation, authService: AuthService, networkMonitor: NetworkMonitor, modelContext: ModelContext) {
        self.currentConversation = conversation
        self.authService = authService
        self.networkMonitor = networkMonitor
        self.modelContext = modelContext
        observeNetworkChanges()
    }
    
    private func observeNetworkChanges() {
        // Auto-retry pending messages when network reconnects
        networkMonitor.$isConnected
            .removeDuplicates()
            .dropFirst() // Skip initial value
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                if isConnected {
                    print("📶 Network reconnected - retrying pending messages")
                    Task { @MainActor in
                        self.retryPendingMessages()
                    }
                } else {
                    print("📴 Network disconnected")
                }
            }
            .store(in: &cancellables)
    }
    
    func startListening() {
        guard let conversationId = currentConversation.id else { return }
        guard let userId = authService.currentUser?.id else { return }
        
        // Update presence when user opens chat (viewing messages is activity)
        // No periodic heartbeat - only update on explicit actions to reduce Firestore writes
        Task {
            await authService.updatePresence(isOnline: true)
        }
        
        // 1. LOAD FROM CACHE FIRST (instant, works offline)
        loadMessagesFromCache()
        
        // 2. UPDATE LOCAL READ STATE (no Firestore write!)
        do {
            try MessageCacheService.shared.markConversationAsRead(
                conversationId: conversationId,
                userId: userId,
                in: modelContext
            )
        } catch {
            print("❌ Error marking conversation as read: \(error)")
        }
        
        // 3. MARK EXISTING UNREAD MESSAGES AS READ IN FIREBASE (for sender's blue ticks)
        Task {
            await markExistingMessagesAsRead()
        }
        
        // 4. START FIRESTORE LISTENER (background sync)
        firestoreService.listenToMessages(conversationId: conversationId, currentUserId: userId) { [weak self] firestoreMessages in
            guard let self = self else { return }
            
            print("🔥 Firestore listener fired with \(firestoreMessages.count) messages")
            
            // Perform all UI updates on the main thread
            Task { @MainActor in
                guard let currentUserId = self.authService.currentUser?.id else { return }
                
                // Save to cache (with status progression protection + tombstone check)
                do {
                    try MessageCacheService.shared.saveMessages(firestoreMessages, currentUserId: currentUserId, in: self.modelContext)
                } catch {
                    print("❌ Error saving messages to cache: \(error)")
                }
                
                // CRITICAL: Acknowledge delivery + mark as read for each NEW incoming message
                for message in firestoreMessages {
                    guard let messageId = message.id else { continue }
                    
                    // Only acknowledge if this message is FOR us (not sent BY us)
                    if message.senderId != currentUserId {
                        Task {
                            do {
                                // Acknowledge delivery
                                try await self.firestoreService.acknowledgeDelivery(
                                    messageId: messageId,
                                    userId: currentUserId
                                )
                                
                                // Mark as read (only NEW messages, not re-marking old ones)
                                try await self.firestoreService.markMessageAsRead(
                                    messageId: messageId,
                                    conversationId: conversationId,
                                    userId: currentUserId
                                )
                            } catch {
                                print("❌ Error acknowledging/marking read: \(error)")
                            }
                        }
                    }
                }
                
                // CRITICAL: UI must read from cache (single source of truth)
                self.loadMessagesFromCache()
                
                // Update local read state
                do {
                    try MessageCacheService.shared.markConversationAsRead(
                        conversationId: conversationId,
                        userId: userId,
                        in: self.modelContext
                    )
                } catch {
                    print("❌ Error marking conversation as read: \(error)")
                }
            }
        }
        
        // Listen to conversation updates (for typing indicators and real-time updates)
        firestoreService.listenToConversation(conversationId: conversationId) { [weak self] conversation in
            guard let self = self else { return }
            if let conversation = conversation {
                self.currentConversation = conversation
            }
        }
    }
    
    private func loadMessagesFromCache() {
        guard let conversationId = currentConversation.id else { return }
        do {
            let localMessages = try MessageCacheService.shared.fetchMessages(
                for: conversationId,
                in: modelContext
            )
            
            // Convert LocalMessage to Message for UI
            let messages = localMessages.map { localMsg -> Message in
                Message(
                    id: localMsg.id,
                    conversationId: localMsg.conversationId,
                    senderId: localMsg.senderId,
                    senderName: localMsg.senderName,
                    senderProfileUrl: nil,
                    text: localMsg.text,
                    imageUrl: localMsg.imageUrl,
                    timestamp: localMsg.timestamp,
                    status: MessageStatus(rawValue: localMsg.status) ?? .sent,
                    readBy: localMsg.readBy
                )
            }
            
            if !messages.isEmpty {
                self.messages = messages
                print("📦 Loaded \(messages.count) messages from local cache")
            }
        } catch {
            print("❌ Error loading messages from cache: \(error)")
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
        
        // Update presence to keep lastSeen fresh while actively messaging
        Task {
            await authService.updatePresence(isOnline: true)
        }
        
        let text = messageText
        let imageData = pendingImageData
        messageText = ""
        pendingImageData = nil
    
        // Set initial status based on network
        let initialStatus: MessageStatus = networkMonitor.isConnected ? .sending : .pending
        
        let message = Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: userId,
            senderName: currentUser.displayName,
            senderProfileUrl: currentUser.profilePictureUrl,
            text: text,
            timestamp: Date(),
            status: initialStatus,
            readBy: [userId],
            localImageData: imageData
        )
        
        // Optimistic UI - add message immediately
        messages.append(message)
        print("🚀 Created message: \(message.id ?? "no-id") status=\(initialStatus.rawValue) (network: \(networkMonitor.isConnected))")
        
        // Save to SwiftData immediately (works offline!)
        do {
            guard let currentUserId = authService.currentUser?.id else { return }
            try MessageCacheService.shared.saveMessage(message, currentUserId: currentUserId, in: modelContext)
            print("💾 Saved to cache: \(message.id ?? "no-id")")
        } catch {
            print("❌ Error saving to cache: \(error)")
        }
        
        // Try to send if online
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
                    
                    // Update cache with sent status
                    guard let currentUserId = authService.currentUser?.id else { return }
                    try MessageCacheService.shared.saveMessage(sentMessage, currentUserId: currentUserId, in: modelContext)
                    print("✅ Message sent: \(sentMessage.id ?? "no-id") status=\(sentMessage.status.rawValue)")
                    
                    // Reload from cache
                    await MainActor.run {
                        loadMessagesFromCache()
                    }
                } catch {
                    print("❌ Send failed: \(error.localizedDescription) - keeping as pending")
                    // Update to pending status (will retry on reconnect)
                    var pendingMessage = message
                    pendingMessage.status = .pending
                    if let currentUserId = authService.currentUser?.id {
                        try? MessageCacheService.shared.saveMessage(pendingMessage, currentUserId: currentUserId, in: modelContext)
                    }
                    
                    // Reload from cache
                    await MainActor.run {
                        loadMessagesFromCache()
                    }
                }
            }
            // If offline, message already saved with .pending status - nothing more to do
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
    
    private func markExistingMessagesAsRead() async {
        guard let conversationId = currentConversation.id else { return }
        guard let userId = authService.currentUser?.id else { return }
        
        // Mark messages from others that aren't already marked as read locally.
        // Rely on message.status to avoid duplicate writes; arrayUnion keeps it idempotent anyway.
        let messagesToMark = messages.filter { $0.senderId != userId && $0.status != .read }
        
        guard !messagesToMark.isEmpty else { return }
        
        print("📖 Marking \(messagesToMark.count) messages as read in Firebase")
        
        for message in messagesToMark {
            if let messageId = message.id {
                do {
                    try await firestoreService.markMessageAsRead(
                        messageId: messageId, 
                        conversationId: conversationId, 
                        userId: userId
                    )
                } catch {
                    // Ignore errors (message likely deleted from ephemeral queue)
                }
            }
        }
    }
    
    func retryPendingMessages() {
        guard let conversationId = currentConversation.id else { return }
        guard let currentUserId = authService.currentUser?.id else { return }
        
        // Query LocalMessage with status = "pending"
        let convId = conversationId
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate<LocalMessage> { localMsg in
                localMsg.conversationId == convId && localMsg.status == "pending"
            }
        )
        
        guard let pendingLocalMessages = try? modelContext.fetch(descriptor) else {
            print("⚠️ No pending messages found")
            return
        }
        
        print("🔄 Retrying \(pendingLocalMessages.count) pending messages")
        
        for localMsg in pendingLocalMessages {
            let message = Message(from: localMsg)
            
            Task {
                do {
                    // Update to sending
                    var sendingMsg = message
                    sendingMsg.status = .sending
                    try? MessageCacheService.shared.saveMessage(sendingMsg, currentUserId: currentUserId, in: modelContext)
                    
                    // Try to send
                    let sentMessage = try await firestoreService.sendMessage(message)
                    
                    // Update with sent status
                    try? MessageCacheService.shared.saveMessage(sentMessage, currentUserId: currentUserId, in: modelContext)
                    print("✅ Retry successful: \(sentMessage.id ?? "no-id")")
                    
                    // Reload UI
                    await MainActor.run {
                        loadMessagesFromCache()
                    }
                } catch {
                    print("❌ Retry failed: \(error.localizedDescription)")
                    // Keep as pending for next reconnect
                    var pendingMsg = message
                    pendingMsg.status = .pending
                    try? MessageCacheService.shared.saveMessage(pendingMsg, currentUserId: currentUserId, in: modelContext)
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
    
    // MARK: - Delete Message
    
    func deleteMessage(_ message: Message) {
        guard let messageId = message.id,
              let conversationId = currentConversation.id,
              let userId = authService.currentUser?.id else {
            print("❌ Cannot delete message: missing required IDs")
            return
        }
        
        do {
            // Delete from local cache (SwiftData + tombstone)
            try MessageCacheService.shared.deleteMessage(
                messageId,
                conversationId: conversationId,
                userId: userId,
                in: modelContext
            )
            
            // Reload messages from cache to update UI
            loadMessagesFromCache()
            
            print("✅ Message deleted successfully")
        } catch {
            print("❌ Error deleting message: \(error.localizedDescription)")
        }
    }
    
}

