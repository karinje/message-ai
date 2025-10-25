//
//  LocalConversationState.swift
//  weftly
//
//  Created on 10/24/25.
//  Local SwiftData model for unread counter calculation (KEY FIX)
//

import Foundation
import SwiftData

@Model
final class LocalConversationState {
    @Attribute(.unique) var uniqueId: String  // conversationId + userId
    var conversationId: String
    var userId: String
    var lastReadTimestamp: Date      // Used for unread counter calculation
    var lastViewedTimestamp: Date    // For "last opened" tracking
    var deletedAt: Date?             // When conversation was deleted (ignore messages before this)
    var deletedMessageIds: [String]  // Individual messages deleted by user
    
    init(
        conversationId: String,
        userId: String,
        lastReadTimestamp: Date = .distantPast,
        lastViewedTimestamp: Date = .distantPast,
        deletedAt: Date? = nil,
        deletedMessageIds: [String] = []
    ) {
        self.uniqueId = "\(conversationId)_\(userId)"
        self.conversationId = conversationId
        self.userId = userId
        self.lastReadTimestamp = lastReadTimestamp
        self.lastViewedTimestamp = lastViewedTimestamp
        self.deletedAt = deletedAt
        self.deletedMessageIds = deletedMessageIds
    }
    
    // Mark conversation as read
    func markAsRead() {
        self.lastReadTimestamp = Date()
        self.lastViewedTimestamp = Date()
    }
    
    // Track deleted message (individual message tombstone)
    func markMessageDeleted(_ messageId: String) {
        if !deletedMessageIds.contains(messageId) {
            deletedMessageIds.append(messageId)
        }
    }
    
    // Check if message was deleted
    func isMessageDeleted(_ messageId: String) -> Bool {
        return deletedMessageIds.contains(messageId)
    }
}
