//
//  Conversation.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import FirebaseFirestore

enum ConversationType: String, Codable {
    case direct = "direct"
    case group = "group"
}

struct Conversation: Identifiable, Codable, Equatable {
    var id: String?
    var type: ConversationType
    var participants: [String] // Array of user IDs
    var participantNames: [String: String] // userId: displayName mapping
    var participantProfileUrls: [String: String] // userId: profileUrl mapping
    var groupName: String?
    var groupIconUrl: String?
    var lastMessage: String?
    var lastMessageSenderId: String?
    var lastMessageTime: Date?
    var unreadCount: [String: Int] // userId: count mapping (deprecated, use lastReadTime)
    var lastReadTime: [String: Date] // userId: timestamp when user last read this conversation
    var typingUsers: [String] // Array of user IDs currently typing
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case participants
        case participantNames
        case participantProfileUrls
        case groupName
        case groupIconUrl
        case lastMessage
        case lastMessageSenderId
        case lastMessageTime
        case unreadCount
        case lastReadTime
        case typingUsers
    }
    
    init(id: String? = nil, type: ConversationType, participants: [String], participantNames: [String: String] = [:], participantProfileUrls: [String: String] = [:], groupName: String? = nil, groupIconUrl: String? = nil, lastMessage: String? = nil, lastMessageSenderId: String? = nil, lastMessageTime: Date? = nil, unreadCount: [String: Int] = [:], lastReadTime: [String: Date] = [:], typingUsers: [String] = []) {
        self.id = id
        self.type = type
        self.participants = participants
        self.participantNames = participantNames
        self.participantProfileUrls = participantProfileUrls
        self.groupName = groupName
        self.groupIconUrl = groupIconUrl
        self.lastMessage = lastMessage
        self.lastMessageSenderId = lastMessageSenderId
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
        self.lastReadTime = lastReadTime
        self.typingUsers = typingUsers
    }
    
    // Custom decoder to handle missing lastReadTime in old documents
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        type = try container.decode(ConversationType.self, forKey: .type)
        participants = try container.decode([String].self, forKey: .participants)
        participantNames = try container.decode([String: String].self, forKey: .participantNames)
        participantProfileUrls = try container.decode([String: String].self, forKey: .participantProfileUrls)
        groupName = try container.decodeIfPresent(String.self, forKey: .groupName)
        groupIconUrl = try container.decodeIfPresent(String.self, forKey: .groupIconUrl)
        lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage)
        lastMessageSenderId = try container.decodeIfPresent(String.self, forKey: .lastMessageSenderId)
        lastMessageTime = try container.decodeIfPresent(Date.self, forKey: .lastMessageTime)
        unreadCount = (try? container.decode([String: Int].self, forKey: .unreadCount)) ?? [:]
        lastReadTime = (try? container.decode([String: Date].self, forKey: .lastReadTime)) ?? [:] // Default to empty if missing
        typingUsers = (try? container.decode([String].self, forKey: .typingUsers)) ?? []
    }
    
    // Helper to get conversation title for UI
    func displayName(for currentUserId: String) -> String {
        if type == .group {
            return groupName ?? "Group Chat"
        } else {
            // For direct chat, show the other person's name
            let otherUserId = participants.first { $0 != currentUserId }
            return participantNames[otherUserId ?? ""] ?? "Unknown"
        }
    }
}

