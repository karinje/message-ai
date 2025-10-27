// Archived old AI models - excluded from build
#if false
import SwiftUI

enum AIPriority: String, Codable {
    case urgent
    case important
    case normal
    
    var color: Color {
        switch self {
        case .urgent: return .red
        case .important: return .orange
        case .normal: return .clear
        }
    }
    
    var icon: String {
        switch self {
        case .urgent: return "exclamationmark.triangle.fill"
        case .important: return "star.fill"
        case .normal: return ""
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .urgent: return .red.opacity(0.1)
        case .important: return .orange.opacity(0.1)
        case .normal: return .clear
        }
    }
    
    // Helper to parse from optional string
    static func from(_ string: String?) -> AIPriority {
        guard let string = string else { return .normal }
        return AIPriority(rawValue: string) ?? .normal
    }
}
#endif

