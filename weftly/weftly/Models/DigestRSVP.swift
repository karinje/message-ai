//
//  DigestRSVP.swift
//  weftly
//
//  Created for unified agent architecture (PR #28)
//  RSVP tracking for events

import Foundation
import SwiftData

@Model
final class DigestRSVP {
    @Attribute(.unique) var id: String
    var eventId: String // Reference to DigestEvent
    var eventTitle: String
    var eventDate: Date
    var conversationId: String
    var messageId: String
    var isHost: Bool // Current user is organizer
    var responsesJSON: String // JSON string of responses map
    var totalInvited: Int
    var createdAt: Date
    
    init(
        id: String,
        eventId: String,
        eventTitle: String,
        eventDate: Date,
        conversationId: String,
        messageId: String,
        isHost: Bool
    ) {
        self.id = id
        self.eventId = eventId
        self.eventTitle = eventTitle
        self.eventDate = eventDate
        self.conversationId = conversationId
        self.messageId = messageId
        self.isHost = isHost
        self.responsesJSON = "{}"
        self.totalInvited = 0
        self.createdAt = Date()
    }
    
    // Computed property to access responses
    var responses: [String: RSVPResponseData] {
        get {
            guard let data = responsesJSON.data(using: .utf8) else { return [:] }
            return (try? JSONDecoder().decode([String: RSVPResponseData].self, from: data)) ?? [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                responsesJSON = json
            }
        }
    }
}

struct RSVPResponseData: Codable {
    let response: String // "yes" | "no" | "maybe"
    let guestCount: Int?
    let note: String?
    let timestamp: Date
}

