//
//  Message.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable, Equatable {
    var id: String?
    var conversationId: String
    var senderId: String
    var senderName: String
    var senderProfileUrl: String?
    var text: String
    var imageUrl: String?
    var timestamp: Date
    var status: MessageStatus
    var readBy: [String] // Array of user IDs who have read this message
    var localImageData: Data?
    
    // AI Features - Priority Detection
    var priority: String? // "urgent", "important", "normal"
    var priorityReason: String?
    var priorityConfidence: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId
        case senderId
        case senderName
        case senderProfileUrl
        case text
        case imageUrl
        case timestamp
        case status
        case readBy
        case priority
        case priorityReason
        case priorityConfidence
    }
    
    init(id: String? = nil, conversationId: String, senderId: String, senderName: String, senderProfileUrl: String? = nil, text: String, imageUrl: String? = nil, timestamp: Date = Date(), status: MessageStatus = .sending, readBy: [String] = [], localImageData: Data? = nil, priority: String? = nil, priorityReason: String? = nil, priorityConfidence: Double? = nil) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.senderProfileUrl = senderProfileUrl
        self.text = text
        self.imageUrl = imageUrl
        self.timestamp = timestamp
        self.status = status
        self.readBy = readBy
        self.localImageData = localImageData
        self.priority = priority
        self.priorityReason = priorityReason
        self.priorityConfidence = priorityConfidence
    }
    
    // Convert from LocalMessage to Message
    init(from localMessage: LocalMessage) {
        self.id = localMessage.id
        self.conversationId = localMessage.conversationId
        self.senderId = localMessage.senderId
        self.senderName = localMessage.senderName
        self.senderProfileUrl = nil  // LocalMessage doesn't store this
        self.text = localMessage.text
        self.imageUrl = localMessage.imageUrl
        self.timestamp = localMessage.timestamp
        self.status = MessageStatus(rawValue: localMessage.status) ?? .pending
        self.readBy = localMessage.readBy
        self.localImageData = nil
        self.priority = nil
        self.priorityReason = nil
        self.priorityConfidence = nil
    }
}

