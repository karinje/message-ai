//
//  ConversationList.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import Foundation
import FirebaseFirestore

struct ConversationList: Identifiable, Codable, Equatable {
    var id: String?
    var name: String
    var conversationIds: [String]  // Deprecated - kept for backward compatibility
    var userIds: [String]  // NEW: Filter by users instead of conversations
    var icon: String? // SF Symbol name
    var isPreset: Bool
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case conversationIds
        case userIds
        case icon
        case isPreset
        case createdAt
        case updatedAt
    }
    
    init(id: String? = nil, name: String, conversationIds: [String] = [], userIds: [String] = [], icon: String? = nil, isPreset: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.conversationIds = conversationIds
        self.userIds = userIds
        self.icon = icon
        self.isPreset = isPreset
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Preset list types
    static var unreadList: ConversationList {
        ConversationList(id: "preset-unread", name: "Unread", icon: "circle.fill", isPreset: true)
    }
    
    static var favoritesList: ConversationList {
        ConversationList(id: "preset-favorites", name: "Favorites", icon: "star.fill", isPreset: true)
    }
    
    static var groupsList: ConversationList {
        ConversationList(id: "preset-groups", name: "Groups", icon: "person.3.fill", isPreset: true)
    }
}

