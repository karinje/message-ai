//
//  MessageCacheService.swift
//  weftly
//
//  Created on 10/24/25.
//  Manages local SwiftData cache for messages (single source of truth)
//

import Foundation
import SwiftData

@MainActor
class MessageCacheService {
    static let shared = MessageCacheService()
    
    private init() {}
    
    // MARK: - Helper Functions
    
    /// Check if new status is a valid progression from current status
    /// Status progression: pending → sending → sent → delivered → read
    /// Never allow backward progression (prevents tick flickering)
    private func shouldUpdateStatus(from currentStatus: String, to newStatus: String) -> Bool {
        let statusOrder: [String] = ["pending", "sending", "sent", "delivered", "read", "failed"]
        
        guard let currentIndex = statusOrder.firstIndex(of: currentStatus),
              let newIndex = statusOrder.firstIndex(of: newStatus) else {
            // Unknown status, allow update
            print("⚠️ Unknown status in progression: \(currentStatus) → \(newStatus), allowing update")
            return true
        }
        
        // Only update if moving forward or staying same
        let canUpdate = newIndex >= currentIndex
        if !canUpdate {
            print("🚫 BLOCKING backward status: \(currentStatus) → \(newStatus)")
        }
        return canUpdate
    }
    
    // MARK: - Message Cache Operations
    
    /// Save a message to local cache
    func saveMessage(_ message: Message, in context: ModelContext) throws {
        // Check if message already exists
        guard let messageId = message.id else {
            print("⚠️ Cannot save message without ID")
            return
        }
        
        // Create a local copy of messageId to capture in predicate
        let idToFind = messageId
        
        // Try to find existing message
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate<LocalMessage> { localMsg in
                localMsg.id == idToFind
            }
        )
        
        let existing = try context.fetch(descriptor).first
        
        if let existing = existing {
            // Only update if something actually changed (avoid unnecessary writes)
            let textChanged = existing.text != message.text
            let imageChanged = existing.imageUrl != message.imageUrl
            let readByChanged = existing.readBy != message.readBy
            
            // For status: only update if it's a forward progression (prevents tick flickering)
            let statusShouldUpdate = existing.status != message.status.rawValue && 
                                    shouldUpdateStatus(from: existing.status, to: message.status.rawValue)
            
            if textChanged || imageChanged || statusShouldUpdate || readByChanged {
                existing.text = message.text
                existing.imageUrl = message.imageUrl
                
                // Only update status if it's moving forward
                if statusShouldUpdate {
                    print("✅ Status progression: \(existing.status) → \(message.status.rawValue) for \(messageId)")
                    existing.status = message.status.rawValue
                } else if existing.status != message.status.rawValue {
                    print("⚠️ Blocked backward status: \(existing.status) ← \(message.status.rawValue) for \(messageId)")
                }
                
                existing.readBy = message.readBy
                existing.lastSyncedAt = Date()
                existing.localOnly = false
            }
            // else: skip update, nothing changed
        } else {
            // Create new message
            let localMessage = LocalMessage(from: message)
            context.insert(localMessage)
            print("💾 Saved NEW message \(messageId) to cache, timestamp=\(localMessage.timestamp)")
        }
        
        try context.save()
    }
    
    /// Save multiple messages to cache (optimized batch version)
    func saveMessages(_ messages: [Message], in context: ModelContext) throws {
        var changesCount = 0
        
        for message in messages {
            guard let messageId = message.id else { continue }
            
            let msgId = messageId  // Local copy for predicate
            let descriptor = FetchDescriptor<LocalMessage>(
                predicate: #Predicate<LocalMessage> { localMsg in
                    localMsg.id == msgId
                }
            )
            
            let existing = try context.fetch(descriptor).first
            
            if let existing = existing {
                // Only update if something actually changed
                let textChanged = existing.text != message.text
                let imageChanged = existing.imageUrl != message.imageUrl
                let readByChanged = existing.readBy != message.readBy
                
                // For status: only update if it's a forward progression
                let statusShouldUpdate = existing.status != message.status.rawValue && 
                                        shouldUpdateStatus(from: existing.status, to: message.status.rawValue)
                
                if textChanged || imageChanged || statusShouldUpdate || readByChanged {
                    existing.text = message.text
                    existing.imageUrl = message.imageUrl
                    
                    // Only update status if it's moving forward
                    if statusShouldUpdate {
                        existing.status = message.status.rawValue
                    } else if existing.status != message.status.rawValue {
                        // Blocked backward progression - log it
                        print("⚠️ Batch: Blocked backward status \(existing.status) ← \(message.status.rawValue) for \(messageId)")
                    }
                    
                    existing.readBy = message.readBy
                    existing.lastSyncedAt = Date()
                    existing.localOnly = false
                    changesCount += 1
                }
            } else {
                // Create new message
                let localMessage = LocalMessage(from: message)
                context.insert(localMessage)
                changesCount += 1
            }
        }
        
        // Only save if we actually made changes
        if changesCount > 0 {
            try context.save()
            print("💾 Batch saved \(changesCount)/\(messages.count) messages to cache")
        }
    }
    
    /// Fetch messages for a conversation (local cache only)
    func fetchMessages(for conversationId: String, in context: ModelContext) throws -> [LocalMessage] {
        let convId = conversationId  // Local copy for predicate capture
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate<LocalMessage> { localMsg in
                localMsg.conversationId == convId
            },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// Delete all messages for a conversation
    func deleteMessages(for conversationId: String, in context: ModelContext) throws {
        let messages = try fetchMessages(for: conversationId, in: context)
        for message in messages {
            context.delete(message)
        }
        try context.save()
    }
    
    // MARK: - Conversation State Operations
    
    /// Get or create conversation state for unread tracking
    func getConversationState(
        for conversationId: String,
        userId: String,
        in context: ModelContext
    ) throws -> LocalConversationState {
        let convId = conversationId  // Local copy for predicate capture
        let descriptor = FetchDescriptor<LocalConversationState>(
            predicate: #Predicate<LocalConversationState> { state in
                state.conversationId == convId
            }
        )
        
        if let existing = try context.fetch(descriptor).first {
            print("📂 Found existing state for \(conversationId): lastRead=\(existing.lastReadTimestamp)")
            return existing
        } else {
            // Create new state
            let state = LocalConversationState(
                conversationId: conversationId,
                userId: userId
            )
            context.insert(state)
            try context.save()
            print("🆕 Created NEW state for \(conversationId): lastRead=\(state.lastReadTimestamp)")
            return state
        }
    }
    
    /// Mark conversation as read (updates lastReadTimestamp)
    func markConversationAsRead(
        conversationId: String,
        userId: String,
        in context: ModelContext
    ) throws {
        let state = try getConversationState(
            for: conversationId,
            userId: userId,
            in: context
        )
        print("✅ Marking conversation as READ: \(conversationId) at \(Date())")
        state.markAsRead()
        try context.save()
    }
    
    /// Calculate unread count for a conversation (100% local - KEY FIX)
    func calculateUnreadCount(
        for conversationId: String,
        currentUserId: String,
        in context: ModelContext
    ) throws -> Int {
        // Get conversation state
        let state = try getConversationState(
            for: conversationId,
            userId: currentUserId,
            in: context
        )
        
        print("📊 Unread calc for \(conversationId): lastRead=\(state.lastReadTimestamp)")
        
        // Local copies for predicate capture
        let convId = conversationId
        let userId = currentUserId
        
        // Get messages from this conversation (not sent by current user)
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate<LocalMessage> { localMsg in
                localMsg.conversationId == convId &&
                localMsg.senderId != userId
            }
        )
        
        let messages = try context.fetch(descriptor)
        print("📊 Found \(messages.count) messages from others")
        
        // Count messages newer than lastReadTimestamp
        let unreadMessages = messages.filter { message in
            message.timestamp > state.lastReadTimestamp
        }
        
        print("📊 Unread count: \(unreadMessages.count) (newer than lastRead)")
        if let newest = messages.max(by: { $0.timestamp < $1.timestamp }) {
            print("📊 Newest message: \(newest.timestamp)")
        }
        
        return unreadMessages.count
    }
    
    /// Calculate total unread count across all conversations
    func calculateTotalUnreadCount(
        for userId: String,
        conversationIds: [String],
        in context: ModelContext
    ) throws -> Int {
        var total = 0
        for conversationId in conversationIds {
            total += try calculateUnreadCount(
                for: conversationId,
                currentUserId: userId,
                in: context
            )
        }
        return total
    }
    
    // MARK: - Cache Cleanup
    
    /// Delete all local cache data (for "Delete All Chats")
    func clearAllCache(in context: ModelContext) throws {
        // Delete all messages
        let messageDescriptor = FetchDescriptor<LocalMessage>()
        let messages = try context.fetch(messageDescriptor)
        for message in messages {
            context.delete(message)
        }
        
        // Delete all conversation states
        let stateDescriptor = FetchDescriptor<LocalConversationState>()
        let states = try context.fetch(stateDescriptor)
        for state in states {
            context.delete(state)
        }
        
        try context.save()
    }
}
