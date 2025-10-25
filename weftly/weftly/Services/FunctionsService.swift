import Foundation
import FirebaseFunctions

enum NetworkError: Error {
    case invalidResponse
    case decodingError
    case functionError(String)
    case timeout
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .functionError(let message):
            return message
        case .timeout:
            return "Request timed out"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

@MainActor
class FunctionsService: ObservableObject {
    static let shared = FunctionsService()
    
    private let functions = Functions.functions()
    private let maxRetries = 3
    
    private init() {
        // Configure timeout (default is 60 seconds)
        // Uncomment for local development:
        // functions.useEmulator(withHost: "localhost", port: 5001)
    }
    
    // MARK: - Generic Function Call
    func callFunction<T: Decodable>(
        _ name: String,
        data: [String: Any],
        retries: Int = 3
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<retries {
            do {
                let result = try await functions.httpsCallable(name).call(data)
                
                guard let resultData = result.data as? [String: Any] else {
                    throw NetworkError.invalidResponse
                }
                
                // Convert to JSON data for decoding
                let jsonData = try JSONSerialization.data(withJSONObject: resultData)
                let decoded = try JSONDecoder().decode(T.self, from: jsonData)
                return decoded
                
            } catch {
                lastError = error
                print("⚠️ Function \(name) failed (attempt \(attempt + 1)/\(retries)): \(error.localizedDescription)")
                
                // Don't retry on certain errors
                if let functionsError = error as? FunctionsErrorCode {
                    if functionsError == .unauthenticated || functionsError == .permissionDenied {
                        throw NetworkError.functionError("Authentication error")
                    }
                }
                
                // Wait before retry with exponential backoff
                if attempt < retries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NetworkError.unknown
    }
    
    // MARK: - Calendar Extraction
    func extractCalendarEvents(
        messageText: String,
        conversationId: String,
        messageId: String
    ) async throws -> [ExtractedEvent] {
        struct Response: Codable {
            let events: [ExtractedEvent]
        }
        
        let data: [String: Any] = [
            "messageText": messageText,
            "conversationId": conversationId,
            "messageId": messageId
        ]
        
        let response: Response = try await callFunction("extractCalendarEvents", data: data)
        return response.events
    }
    
    // MARK: - RSVP Tracking
    func trackRSVP(
        conversationId: String,
        eventId: String?
    ) async throws -> RSVPResponse {
        var data: [String: Any] = [
            "conversationId": conversationId
        ]
        
        if let eventId = eventId {
            data["eventId"] = eventId
        }
        
        return try await callFunction("trackRSVP", data: data)
    }
    
    // MARK: - Decision Summarization
    func summarizeDecisions(
        conversationId: String,
        query: String? = nil
    ) async throws -> [AIDecision] {
        struct Response: Codable {
            let decisions: [AIDecision]
        }
        
        var data: [String: Any] = [
            "conversationId": conversationId
        ]
        
        if let query = query {
            data["query"] = query
        }
        
        let response: Response = try await callFunction("summarizeDecisions", data: data)
        return response.decisions
    }
    
    // MARK: - Priority Detection
    func detectPriority(messageText: String) async throws -> MessagePriority {
        struct Response: Codable {
            let priority: String
            let reason: String
            let confidence: Double
        }
        
        let data: [String: Any] = [
            "messageText": messageText
        ]
        
        let response: Response = try await callFunction("detectPriority", data: data)
        
        return MessagePriority(
            level: response.priority,
            reason: response.reason,
            confidence: response.confidence
        )
    }
    
    // MARK: - Deadline Extraction
    func extractDeadlines(
        messageText: String,
        conversationId: String,
        messageId: String
    ) async throws -> [Deadline] {
        struct Response: Codable {
            let deadlines: [Deadline]
        }
        
        let data: [String: Any] = [
            "messageText": messageText,
            "conversationId": conversationId,
            "messageId": messageId
        ]
        
        let response: Response = try await callFunction("extractDeadlines", data: data)
        return response.deadlines
    }
    
    // MARK: - AI Chat Agent
    func sendAIChatMessage(
        message: String,
        chatId: String,
        history: [AIChatMessage]
    ) async throws -> AIChatAgentResponse {
        let historyData = history.map { msg in
            [
                "role": msg.role.rawValue,
                "content": msg.content
            ]
        }
        
        let data: [String: Any] = [
            "query": message,
            "chatId": chatId,
            "history": historyData
        ]
        
        return try await callFunction("aiChatAgent", data: data)
    }
}

// MARK: - Supporting Types
struct MessagePriority: Codable {
    let level: String  // "urgent", "important", "normal"
    let reason: String
    let confidence: Double
}

struct AIChatAgentResponse: Codable {
    let response: String
    let toolsUsed: [String]?
}

