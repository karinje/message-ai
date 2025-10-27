//
//  DigestEvent.swift
//  weftly
//
//  Created for unified agent architecture (PR #28)
//  Calendar events extracted by AI

import Foundation
import SwiftData

@Model
final class DigestEvent {
    @Attribute(.unique) var id: String
    var title: String
    var date: Date
    var time: String?
    var location: String?
    var conversationId: String
    var messageId: String
    var confidence: Double
    var status: String // "pending" | "accepted" | "dismissed"
    var addedToCalendar: Bool
    var createdAt: Date
    var lastMentionedAt: Date
    
    init(
        id: String,
        title: String,
        date: Date,
        conversationId: String,
        messageId: String,
        time: String? = nil,
        location: String? = nil,
        confidence: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.conversationId = conversationId
        self.messageId = messageId
        self.time = time
        self.location = location
        self.confidence = confidence
        self.status = "pending"
        self.addedToCalendar = false
        self.createdAt = Date()
        self.lastMentionedAt = Date()
    }
}

