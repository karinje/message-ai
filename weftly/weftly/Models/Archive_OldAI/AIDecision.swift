import Foundation

struct AIDecision: Codable, Identifiable {
    var id: String
    var topic: String
    var decision: String
    var participants: [String]  // User IDs who agreed
    var confidence: Double
    var timestamp: Date
    var messageIds: [String]  // Thread leading to decision
    var conversationId: String
    var extractedAt: Date
    
    init(
        id: String = UUID().uuidString,
        topic: String,
        decision: String,
        participants: [String],
        confidence: Double,
        timestamp: Date,
        messageIds: [String] = [],
        conversationId: String,
        extractedAt: Date = Date()
    ) {
        self.id = id
        self.topic = topic
        self.decision = decision
        self.participants = participants
        self.confidence = confidence
        self.timestamp = timestamp
        self.messageIds = messageIds
        self.conversationId = conversationId
        self.extractedAt = extractedAt
    }
    
    // MARK: - Helper Methods
    func participantNames(from users: [User]) -> [String] {
        let userDict = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
        return participants.compactMap { userId in
            userDict[userId]?.displayName
        }
    }
    
    func participantCount() -> Int {
        participants.count
    }
}

