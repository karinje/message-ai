//
//  BroadcastList.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import Foundation
import FirebaseFirestore

struct BroadcastList: Identifiable, Codable, Equatable {
    var id: String?
    var name: String
    var recipientIds: [String] // User IDs
    var lastUsed: Date?
    var messageCount: Int
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case recipientIds
        case lastUsed
        case messageCount
        case createdAt
    }
    
    init(id: String? = nil, name: String, recipientIds: [String] = [], lastUsed: Date? = nil, messageCount: Int = 0, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.recipientIds = recipientIds
        self.lastUsed = lastUsed
        self.messageCount = messageCount
        self.createdAt = createdAt
    }
}

