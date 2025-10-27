import Foundation
import FirebaseFunctions
import Combine

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
}
 
