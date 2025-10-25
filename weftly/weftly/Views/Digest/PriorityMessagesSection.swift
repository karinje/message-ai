import SwiftUI

struct PriorityMessagesSection: View {
    let messages: [PriorityMessage]
    let viewModel: DigestViewModel
    @State private var isExpanded = true
    
    var urgentMessages: [PriorityMessage] {
        messages.filter { $0.priority == "urgent" }
    }
    
    var importantMessages: [PriorityMessage] {
        messages.filter { $0.priority == "important" }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    
                    Text("Priority Messages")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("\(messages.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 12) {
                    // Urgent messages first
                    if !urgentMessages.isEmpty {
                        ForEach(urgentMessages) { message in
                            PriorityMessageCard(message: message, viewModel: viewModel)
                        }
                    }
                    
                    // Important messages second
                    if !importantMessages.isEmpty {
                        ForEach(importantMessages) { message in
                            PriorityMessageCard(message: message, viewModel: viewModel)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct PriorityMessageCard: View {
    let message: PriorityMessage
    let viewModel: DigestViewModel
    @State private var showDetails = false
    @State private var showChatHint = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with priority badge and dismiss button
            HStack {
                if let priorityLevel = message.priorityLevel {
                    PriorityBadgeView(priority: priorityLevel, size: .medium)
                }
                
                Spacer()
                
                Text(message.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button(action: {
                    Task {
                        await viewModel.dismissPriorityMessage(message)
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Sender name
            Text(message.senderName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            // Message text
            Text(message.text)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(showDetails ? nil : 3)
            
            // Reason (collapsed by default)
            if showDetails {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    
                    Text(message.priorityReason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Show more/less button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDetails.toggle()
                    }
                }) {
                    Text(showDetails ? "Show less" : "Why is this priority?")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                // View in Chat hint (TODO: Add proper navigation)
                Button(action: {
                    showChatHint = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "message.fill")
                            .font(.caption)
                        Text("View in Chat")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                }
                .alert("Open Chat", isPresented: $showChatHint) {
                    Button("OK") { }
                } message: {
                    Text("Navigate to the Chats tab to view this conversation.\n\n(Full navigation coming in next update)")
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(message.isUrgent ? Color.red.opacity(0.05) : Color.orange.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(message.isUrgent ? Color.red.opacity(0.2) : Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ScrollView {
        PriorityMessagesSection(
            messages: [
            PriorityMessage(
                id: "1",
                conversationId: "conv1",
                senderId: "user1",
                senderName: "Sarah",
                text: "EMERGENCY! Pick up Sam from school NOW",
                timestamp: Date().addingTimeInterval(-3600),
                priority: "urgent",
                priorityReason: "The message indicates an emergency situation requiring immediate action",
                priorityConfidence: 1.0
            ),
            PriorityMessage(
                id: "2",
                conversationId: "conv1",
                senderId: "user2",
                senderName: "John",
                text: "Can you RSVP for the party by tonight? Need final headcount",
                timestamp: Date().addingTimeInterval(-7200),
                priority: "important",
                priorityReason: "The message requires attention today with a specific deadline",
                priorityConfidence: 0.9
            )
        ],
            viewModel: DigestViewModel(authService: AuthService())
        )
        .padding()
    }
}

