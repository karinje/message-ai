import Foundation

/// A message that has been flagged as urgent or important by AI
struct PriorityMessage: Identifiable, Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let senderName: String
    let text: String
    let timestamp: Date
    let priority: String // "urgent" or "important"
    let priorityReason: String
    let priorityConfidence: Double
    var dismissedBy: [String]? // Array of user IDs who dismissed this
    
    var priorityLevel: AIPriority? {
        AIPriority(rawValue: priority)
    }
    
    var isUrgent: Bool {
        priority == "urgent"
    }
    
    func isDismissedBy(userId: String) -> Bool {
        dismissedBy?.contains(userId) ?? false
    }
}

