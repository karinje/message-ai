import Foundation

enum RSVPStatus: String, Codable {
    case yes
    case no
    case maybe
    case noReply = "no_reply"
}

struct UserRSVP: Codable {
    var status: RSVPStatus
    var numberOfGuests: Int?
    var note: String?
    var respondedAt: Date?
}

struct RSVPResponse: Codable, Identifiable {
    var id: String
    var eventTitle: String
    var eventDate: Date
    var conversationId: String
    var responses: [String: UserRSVP]  // userId: response
    var totalParticipants: Int
    var lastUpdated: Date
    var messageId: String
    
    init(
        id: String = UUID().uuidString,
        eventTitle: String,
        eventDate: Date,
        conversationId: String,
        responses: [String: UserRSVP] = [:],
        totalParticipants: Int,
        lastUpdated: Date = Date(),
        messageId: String
    ) {
        self.id = id
        self.eventTitle = eventTitle
        self.eventDate = eventDate
        self.conversationId = conversationId
        self.responses = responses
        self.totalParticipants = totalParticipants
        self.lastUpdated = lastUpdated
        self.messageId = messageId
    }
    
    // MARK: - Helper Methods
    func percentageResponded() -> Double {
        guard totalParticipants > 0 else { return 0.0 }
        let responded = responses.values.filter { $0.status != .noReply }.count
        return Double(responded) / Double(totalParticipants) * 100.0
    }
    
    func needsReminderUsers() -> [String] {
        responses.filter { $0.value.status == .noReply }.map { $0.key }
    }
    
    func yesCount() -> Int {
        responses.values.filter { $0.status == .yes }.count
    }
    
    func noCount() -> Int {
        responses.values.filter { $0.status == .no }.count
    }
    
    func maybeCount() -> Int {
        responses.values.filter { $0.status == .maybe }.count
    }
    
    func noReplyCount() -> Int {
        responses.values.filter { $0.status == .noReply }.count
    }
}

