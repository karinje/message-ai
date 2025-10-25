import Foundation
import SwiftData

enum DeadlinePriority: String, Codable {
    case high
    case medium
    case low
}

@Model
final class Deadline: Codable {
    @Attribute(.unique) var id: String
    var task: String
    var dueDate: Date
    var priority: String  // Store as String for SwiftData compatibility
    var conversationId: String
    var messageId: String
    var completed: Bool
    var confidence: Double
    var createdAt: Date
    var reminderSent: Bool
    var dismissedBy: [String]? // Array of user IDs who dismissed this deadline
    
    var priorityEnum: DeadlinePriority {
        get { DeadlinePriority(rawValue: priority) ?? .medium }
        set { priority = newValue.rawValue }
    }
    
    init(
        id: String = UUID().uuidString,
        task: String,
        dueDate: Date,
        priority: DeadlinePriority = .medium,
        conversationId: String,
        messageId: String,
        completed: Bool = false,
        confidence: Double,
        createdAt: Date = Date(),
        reminderSent: Bool = false,
        dismissedBy: [String]? = nil
    ) {
        self.id = id
        self.task = task
        self.dueDate = dueDate
        self.priority = priority.rawValue
        self.conversationId = conversationId
        self.messageId = messageId
        self.completed = completed
        self.confidence = confidence
        self.createdAt = createdAt
        self.reminderSent = reminderSent
        self.dismissedBy = dismissedBy
    }
    
    // MARK: - Helper Methods
    func isDueToday() -> Bool {
        Calendar.current.isDateInToday(dueDate)
    }
    
    func isDueTomorrow() -> Bool {
        Calendar.current.isDateInTomorrow(dueDate)
    }
    
    func isOverdue() -> Bool {
        dueDate < Date() && !completed
    }
    
    func daysUntilDue() -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
    
    func isDismissedBy(userId: String) -> Bool {
        dismissedBy?.contains(userId) ?? false
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, task, dueDate, priority, conversationId
        case messageId, completed, confidence, createdAt, reminderSent, dismissedBy
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.task = try container.decode(String.self, forKey: .task)
        self.dueDate = try container.decode(Date.self, forKey: .dueDate)
        self.priority = try container.decode(String.self, forKey: .priority)
        self.conversationId = try container.decode(String.self, forKey: .conversationId)
        self.messageId = try container.decode(String.self, forKey: .messageId)
        self.completed = try container.decode(Bool.self, forKey: .completed)
        self.confidence = try container.decode(Double.self, forKey: .confidence)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.reminderSent = try container.decode(Bool.self, forKey: .reminderSent)
        self.dismissedBy = try container.decodeIfPresent([String].self, forKey: .dismissedBy)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(task, forKey: .task)
        try container.encode(dueDate, forKey: .dueDate)
        try container.encode(priority, forKey: .priority)
        try container.encode(conversationId, forKey: .conversationId)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(completed, forKey: .completed)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(reminderSent, forKey: .reminderSent)
        try container.encodeIfPresent(dismissedBy, forKey: .dismissedBy)
    }
}

