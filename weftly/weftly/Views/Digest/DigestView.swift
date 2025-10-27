//
//  DigestView.swift
//  weftly
//
//  Created for unified agent architecture (PR #32)
//  Main Digest tab displaying AI-extracted items

import SwiftUI
import SwiftData

struct DigestView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DigestEvent.date) private var events: [DigestEvent]
    @Query(sort: \DigestDeadline.dueDate) private var deadlines: [DigestDeadline]
    @Query(sort: \DigestPriorityMessage.timestamp, order: .reverse) private var priorityMessages: [DigestPriorityMessage]
    @Query(sort: \DigestRSVP.eventDate) private var rsvps: [DigestRSVP]
    @Query(sort: \DigestSuggestion.createdAt, order: .reverse) private var suggestions: [DigestSuggestion]
    
    var pendingEvents: [DigestEvent] { events.filter { $0.status == "pending" } }
    var pendingDeadlines: [DigestDeadline] { deadlines.filter { $0.status == "pending" } }
    var pendingSuggestions: [DigestSuggestion] { suggestions.filter { $0.status == "pending" } }
    var pendingPriorityMessages: [DigestPriorityMessage] { priorityMessages.filter { $0.status == "pending" } }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Proactive suggestions (top priority)
                    if !pendingSuggestions.isEmpty {
                        SuggestionsSection(suggestions: pendingSuggestions)
                    }
                    
                    // Priority messages
                    if !pendingPriorityMessages.isEmpty {
                        PriorityMessagesSection(messages: pendingPriorityMessages)
                    }
                    
                    // Calendar events
                    if !pendingEvents.isEmpty {
                        EventsSection(events: pendingEvents)
                    }
                    
                    // Deadlines
                    if !pendingDeadlines.isEmpty {
                        DeadlinesSection(deadlines: pendingDeadlines)
                    }
                    
                    // RSVPs
                    if !rsvps.isEmpty {
                        RSVPSection(rsvps: rsvps)
                    }
                    
                    // Empty state
                    if pendingEvents.isEmpty && pendingDeadlines.isEmpty && 
                       pendingPriorityMessages.isEmpty && rsvps.isEmpty && pendingSuggestions.isEmpty {
                        ContentUnavailableView(
                            "No insights yet",
                            systemImage: "sparkles",
                            description: Text("Enable AI for conversations to start seeing events, deadlines, and important messages here.")
                        )
                        .padding(.top, 100)
                            }
                        }
                        .padding()
                    }
            .navigationTitle("Digest")
        }
        .onAppear {
            if let userId = AuthService.shared.currentUser?.id {
                DigestService.shared.startListening(userId: userId, context: modelContext)
            }
        }
    }
}

// MARK: - Section Views

struct EventsSection: View {
    let events: [DigestEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📅 Upcoming Events")
                .font(.headline)
            
            ForEach(events) { event in
                EventCard(event: event)
            }
        }
    }
}

struct DeadlinesSection: View {
    let deadlines: [DigestDeadline]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⏰ Deadlines")
                .font(.headline)
            
            ForEach(deadlines) { deadline in
                DeadlineCard(deadline: deadline)
            }
        }
    }
}

struct PriorityMessagesSection: View {
    let messages: [DigestPriorityMessage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🚨 Important Messages")
                .font(.headline)
            
            ForEach(messages) { message in
                PriorityMessageCard(message: message)
            }
        }
    }
}

struct RSVPSection: View {
    let rsvps: [DigestRSVP]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("✋ RSVPs")
                .font(.headline)
            
            ForEach(rsvps) { rsvp in
                RSVPCard(rsvp: rsvp)
            }
        }
    }
}

struct SuggestionsSection: View {
    let suggestions: [DigestSuggestion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 Suggestions")
                .font(.headline)
            
            ForEach(suggestions) { suggestion in
                SuggestionCard(suggestion: suggestion)
            }
        }
    }
}

// MARK: - Card Views (Simple implementations)

struct EventCard: View {
    let event: DigestEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(event.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let time = event.time {
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(Int(event.confidence * 100))%")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            HStack(spacing: 12) {
                Button("Add to Calendar") {}
                    .buttonStyle(.bordered)
                    .font(.caption)
                
                Button("Dismiss") {}
                    .buttonStyle(.borderless)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DeadlineCard: View {
    let deadline: DigestDeadline
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(deadline.task)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Due: \(deadline.dueDate, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Mark Complete") {}
                .buttonStyle(.bordered)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PriorityMessageCard: View {
    let message: DigestPriorityMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(message.priority.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(message.priority == "urgent" ? .red : .orange)
                
                Spacer()
            }
            
            Text(message.messageText)
                .font(.subheadline)
            
            Text(message.reason)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RSVPCard: View {
    let rsvp: DigestRSVP
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(rsvp.eventTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Date: \(rsvp.eventDate, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Responses: \(rsvp.responses.count)")
                .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SuggestionCard: View {
    let suggestion: DigestSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(suggestion.suggestionDescription)
                .font(.subheadline)
            
            HStack {
                Button("Accept") {}
                    .buttonStyle(.bordered)
                    .font(.caption)
                
                Button("Dismiss") {}
                    .buttonStyle(.borderless)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}
