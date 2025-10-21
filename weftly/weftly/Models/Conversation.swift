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

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    var type: ConversationType
    var participants: [String] // Array of user IDs
    var participantNames: [String: String] // userId: displayName mapping
    var participantProfileUrls: [String: String] // userId: profileUrl mapping
    var groupName: String?
    var groupIconUrl: String?
    var lastMessage: String?
    var lastMessageSenderId: String?
    var lastMessageTime: Date?
    var unreadCount: [String: Int] // userId: count mapping
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
        case typingUsers
    }
    
    init(id: String? = nil, type: ConversationType, participants: [String], participantNames: [String: String] = [:], participantProfileUrls: [String: String] = [:], groupName: String? = nil, groupIconUrl: String? = nil, lastMessage: String? = nil, lastMessageSenderId: String? = nil, lastMessageTime: Date? = nil, unreadCount: [String: Int] = [:], typingUsers: [String] = []) {
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
        self.typingUsers = typingUsers
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

