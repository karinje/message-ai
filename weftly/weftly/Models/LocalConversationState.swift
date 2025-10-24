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
    @Attribute(.unique) var conversationId: String
    var userId: String
    var lastReadTimestamp: Date      // KEY: Used for unread counter calculation
    var lastViewedTimestamp: Date    // For "last opened" tracking
    
    init(
        conversationId: String,
        userId: String,
        lastReadTimestamp: Date = .distantPast,
        lastViewedTimestamp: Date = .distantPast
    ) {
        self.conversationId = conversationId
        self.userId = userId
        self.lastReadTimestamp = lastReadTimestamp
        self.lastViewedTimestamp = lastViewedTimestamp
    }
    
    // Mark conversation as read (updates lastReadTimestamp to now)
    func markAsRead() {
        self.lastReadTimestamp = Date()
        self.lastViewedTimestamp = Date()
    }
}
