import Foundation
import SwiftUI
import Combine

@MainActor
class AssistantViewModel: ObservableObject {
    @Published var messages: [AIChatMessage] = []
    @Published var currentChatId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var inputText = ""
    
    private let functionsService = FunctionsService.shared
    
    init() {
        // Load or create chat session
        loadChatHistory()
    }
    
    func loadChatHistory() {
        // For now, create a new chat ID if none exists
        if currentChatId == nil {
            currentChatId = UUID().uuidString
        }
        
        // TODO: Load from Firestore in future
        // For now, add welcome message
        if messages.isEmpty {
            messages.append(AIChatMessage(
                role: .assistant,
                content: "Hi! I'm your AI assistant. I can help you search messages, summarize conversations, translate text, check your calendar, and more. What can I help you with?"
            ))
        }
    }
    
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add user message
        let userMessage = AIChatMessage(
            role: .user,
            content: trimmedText
        )
        messages.append(userMessage)
        
        // Clear input
        inputText = ""
        
        // Show loading
        isLoading = true
        errorMessage = nil
        
        do {
            // Call AI agent
            let response = try await functionsService.sendAIChatMessage(
                message: trimmedText,
                chatId: currentChatId ?? UUID().uuidString,
                history: messages
            )
            
            // Add assistant response
            let assistantMessage = AIChatMessage(
                role: .assistant,
                content: response.response,
                toolsUsed: response.toolsUsed
            )
            messages.append(assistantMessage)
            
        } catch {
            errorMessage = "Failed to get response: \(error.localizedDescription)"
            print("❌ AI chat error: \(error)")
            
            // Add error message
            let errorMsg = AIChatMessage(
                role: .assistant,
                content: "Sorry, I couldn't process that request. Please try again."
            )
            messages.append(errorMsg)
        }
        
        isLoading = false
    }
    
    func handleQuickAction(_ action: QuickAction) async {
        let query = action.query
        await sendMessage(query)
    }
    
    func clearChat() {
        messages.removeAll()
        currentChatId = UUID().uuidString
        loadChatHistory()
    }
}

// MARK: - Quick Action Types
enum QuickAction: String, CaseIterable, Identifiable {
    case calendar = "Show Calendar"
    case rsvps = "Pending RSVPs"
    case deadlines = "My Deadlines"
    case search = "Search Messages"
    case translate = "Translate"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .rsvps: return "hand.raised"
        case .deadlines: return "alarm"
        case .search: return "magnifyingglass"
        case .translate: return "globe"
        }
    }
    
    var query: String {
        switch self {
        case .calendar: return "Show me my upcoming events from my messages"
        case .rsvps: return "What RSVPs are pending?"
        case .deadlines: return "Show me my upcoming deadlines"
        case .search: return "Help me search my messages"
        case .translate: return "I need to translate a message"
        }
    }
}

