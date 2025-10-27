//
//  DigestDeadline.swift
//  weftly
//
//  Created for unified agent architecture (PR #28)
//  Deadlines extracted by AI

import Foundation
import SwiftData

@Model
final class DigestDeadline {
    @Attribute(.unique) var id: String
    var task: String
    var dueDate: Date
    var priority: String // "high" | "medium" | "low"
    var assignedTo: String // user ID
    var conversationId: String
    var messageId: String
    var confidence: Double
    var status: String // "pending" | "completed" | "dismissed"
    var completed: Bool
    var createdAt: Date
    
    init(
        id: String,
        task: String,
        dueDate: Date,
        assignedTo: String,
        conversationId: String,
        messageId: String,
        priority: String = "medium",
        confidence: Double = 0.0
    ) {
        self.id = id
        self.task = task
        self.dueDate = dueDate
        self.assignedTo = assignedTo
        self.conversationId = conversationId
        self.messageId = messageId
        self.priority = priority
        self.confidence = confidence
        self.status = "pending"
        self.completed = false
        self.createdAt = Date()
    }
}

