//
//  DigestPriorityMessage.swift
//  weftly
//
//  Created for unified agent architecture (PR #28)
//  Priority messages flagged by AI

import Foundation
import SwiftData

@Model
final class DigestPriorityMessage {
    @Attribute(.unique) var id: String // Same as message ID
    var messageText: String
    var priority: String // "urgent" | "important"
    var reason: String
    var requiresAction: Bool
    var conversationId: String
    var senderId: String
    var senderName: String
    var timestamp: Date
    var status: String // "pending" | "dismissed"
    
    init(
        id: String,
        messageText: String,
        priority: String,
        reason: String,
        conversationId: String,
        senderId: String,
        senderName: String,
        timestamp: Date,
        requiresAction: Bool = false
    ) {
        self.id = id
        self.messageText = messageText
        self.priority = priority
        self.reason = reason
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.timestamp = timestamp
        self.requiresAction = requiresAction
        self.status = "pending"
    }
}

