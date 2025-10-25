import Foundation
import SwiftData

@Model
final class ExtractedEvent: Codable {
    @Attribute(.unique) var id: String
    var title: String
    var date: Date
    var location: String?
    var confidence: Double
    var addedToCalendar: Bool
    var messageId: String
    var conversationId: String
    var extractedAt: Date
    var notified: Bool
    
    init(
        id: String = UUID().uuidString,
        title: String,
        date: Date,
        location: String? = nil,
        confidence: Double,
        addedToCalendar: Bool = false,
        messageId: String,
        conversationId: String,
        extractedAt: Date = Date(),
        notified: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.confidence = confidence
        self.addedToCalendar = addedToCalendar
        self.messageId = messageId
        self.conversationId = conversationId
        self.extractedAt = extractedAt
        self.notified = notified
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, title, date, location, confidence
        case addedToCalendar, messageId, conversationId
        case extractedAt, notified
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.date = try container.decode(Date.self, forKey: .date)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.confidence = try container.decode(Double.self, forKey: .confidence)
        self.addedToCalendar = try container.decode(Bool.self, forKey: .addedToCalendar)
        self.messageId = try container.decode(String.self, forKey: .messageId)
        self.conversationId = try container.decode(String.self, forKey: .conversationId)
        self.extractedAt = try container.decode(Date.self, forKey: .extractedAt)
        self.notified = try container.decode(Bool.self, forKey: .notified)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(addedToCalendar, forKey: .addedToCalendar)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(conversationId, forKey: .conversationId)
        try container.encode(extractedAt, forKey: .extractedAt)
        try container.encode(notified, forKey: .notified)
    }
}

