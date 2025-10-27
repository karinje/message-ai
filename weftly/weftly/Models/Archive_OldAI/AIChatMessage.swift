// Archived old AI models - excluded from build
#if false
import Foundation

enum AIChatRole: String, Codable {
    case user
    case assistant
}
#endif

struct AIChatMessage: Codable, Identifiable {
    var id: String
    var role: AIChatRole
    var content: String
    var timestamp: Date
    var toolsUsed: [String]?
    
    init(
        id: String = UUID().uuidString,
        role: AIChatRole,
        content: String,
        timestamp: Date = Date(),
        toolsUsed: [String]? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.toolsUsed = toolsUsed
    }
}

struct AIChat: Codable, Identifiable {
    var id: String
    var userId: String
    var messages: [AIChatMessage]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        messages: [AIChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

