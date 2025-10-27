//
//  AssistantChatView.swift
//  weftly
//
//  Created for unified agent architecture (PR #32)
//  AI Chat interface

import SwiftUI
import SwiftData

struct AssistantChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var messages: [AIChatMessage] = []
    @State private var inputText = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isProcessing {
                                TypingIndicatorView()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input
                HStack(spacing: 12) {
                    TextField("Ask anything about your messages...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(inputText.isEmpty ? .gray : .blue)
                    }
                    .disabled(inputText.isEmpty || isProcessing)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Initialize with welcome message
            if messages.isEmpty {
                messages.append(AIChatMessage(role: .assistant, content: "Hi! I can help you find information in your messages, track events, deadlines, and more. What would you like to know?"))
            }
        }
    }
    
    func sendMessage() {
        let userMessage = AIChatMessage(role: .user, content: inputText)
        messages.append(userMessage)
        
        let query = inputText
        inputText = ""
        isProcessing = true
        
        Task {
            do {
                let response = try await queryAIAssistant(query: query)
                let aiMessage = AIChatMessage(role: .assistant, content: response)
                messages.append(aiMessage)
            } catch {
                let errorMessage = AIChatMessage(role: .assistant, content: "Sorry, I couldn't process that. Please try again.")
                messages.append(errorMessage)
            }
            
            isProcessing = false
        }
    }
    
    func queryAIAssistant(query: String) async throws -> String {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw NSError(domain: "AIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        // Get all enabled threads
        let descriptor = FetchDescriptor<LocalConversationState>(
            predicate: #Predicate { $0.aiIndexingEnabled == true }
        )
        let enabledStates = try modelContext.fetch(descriptor)
        let enabledThreadIds = enabledStates.map { $0.conversationId }
        
        // Get recent messages per thread
        var recentMessagesByThread: [String: [[String: Any]]] = [:]
        
        for threadId in enabledThreadIds {
            let msgDescriptor = FetchDescriptor<LocalMessage>(
                predicate: #Predicate { $0.conversationId == threadId },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            var msgDescriptor2 = msgDescriptor
            msgDescriptor2.fetchLimit = 30
            
            let messages = try modelContext.fetch(msgDescriptor2).reversed()
            
            recentMessagesByThread[threadId] = messages.map { [
                "id": $0.id,
                "text": $0.text,
                "senderId": $0.senderId,
                "senderName": $0.senderName,
                "timestamp": Int($0.timestamp.timeIntervalSince1970 * 1000)
            ]}
        }
        
        // Call Firebase Function
        let callable = FunctionsService.shared.functions.httpsCallable("aiChatQuery")
        
        let requestData: [String: Any] = [
            "userId": userId,
            "query": query,
            "enabledThreadIds": enabledThreadIds,
            "recentMessagesByThread": recentMessagesByThread
        ]
        
        let result = try await callable.call(requestData)
        
        guard let data = result.data as? [String: Any],
              let response = data["response"] as? String else {
            throw NSError(domain: "AIService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        return response
    }
}

// MARK: - Supporting Views

struct ChatBubble: View {
    let message: AIChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.role == .user ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(18)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .opacity(dotCount >= index ? 1.0 : 0.3)
                }
            }
            .padding(12)
            .background(Color(.systemGray5))
            .cornerRadius(18)
            
            Spacer()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

// MARK: - Models

struct AIChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp = Date()
    
    enum Role {
        case user
        case assistant
    }
}
