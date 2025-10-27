//
//  LocalMessage.swift
//  weftly
//
//  Created on 10/24/25.
//  Local SwiftData model for message caching (single source of truth for UI)
//

import Foundation
import SwiftData

@Model
final class LocalMessage {
    @Attribute(.unique) var id: String
    var conversationId: String
    var senderId: String
    var senderName: String
    var senderProfileUrl: String?
    var text: String
    var imageUrl: String?
    var timestamp: Date
    var status: String  // MessageStatus.rawValue
    var readBy: [String]
    var lastSyncedAt: Date
    var localOnly: Bool  // True for pending sends in queue
    
    init(
        id: String,
        conversationId: String,
        senderId: String,
        senderName: String,
        senderProfileUrl: String? = nil,
        text: String,
        imageUrl: String? = nil,
        timestamp: Date,
        status: String,
        readBy: [String] = [],
        lastSyncedAt: Date = Date(),
        localOnly: Bool = false
    ) {
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
        self.lastSyncedAt = lastSyncedAt
        self.localOnly = localOnly
    }
    
    // Convert from Firestore Message to LocalMessage
    convenience init(from message: Message) {
        self.init(
            id: message.id ?? UUID().uuidString,
            conversationId: message.conversationId,
            senderId: message.senderId,
            senderName: message.senderName,
            senderProfileUrl: message.senderProfileUrl,
            text: message.text,
            imageUrl: message.imageUrl,
            timestamp: message.timestamp,
            status: message.status.rawValue,
            readBy: message.readBy,
            lastSyncedAt: Date(),
            localOnly: false
        )
    }
}
