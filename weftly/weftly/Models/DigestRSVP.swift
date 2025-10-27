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
    var status: String // "pending" | "dismissed"
    var createdAt: Date
    var lastUpdated: Date // Triggers UI refresh when responses change
    
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
        self.status = "pending"
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
    
    // Computed property to access responses
    var responses: [String: RSVPResponseData] {
        get {
            guard let data = responsesJSON.data(using: .utf8) else { return [:] }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()

                if let number = try? container.decode(Double.self) {
                    return Date(timeIntervalSince1970: number)
                }

                let string = try container.decode(String.self)

                // Try ISO8601 with timezone first
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = isoFormatter.date(from: string) {
                    return date
                }

                // Try ISO8601 without fractional seconds
                isoFormatter.formatOptions = [.withInternetDateTime]
                if let date = isoFormatter.date(from: string) {
                    return date
                }

                // Fallback: explicit formatter without timezone (assume Pacific Time)
                let noTZFormatter = DateFormatter()
                noTZFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                noTZFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
                if let date = noTZFormatter.date(from: string) {
                    return date
                }

                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date format: \(string)")
            }

            if let decoded = try? decoder.decode([String: RSVPResponseData].self, from: data) {
                return decoded
            }

            return [:]
        }
        set {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .custom { date, encoder in
                var container = encoder.singleValueContainer()
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                var isoString = formatter.string(from: date)
                if isoString.isEmpty {
                    formatter.formatOptions = [.withInternetDateTime]
                    isoString = formatter.string(from: date)
                }
                try container.encode(isoString)
            }
            if let data = try? encoder.encode(newValue),
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

private struct LegacyRSVPResponseData: Codable {
    let response: String
    let guestCount: Int?
    let note: String?
    let timestamp: Double
}

