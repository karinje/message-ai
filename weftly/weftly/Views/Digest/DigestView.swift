//
//  DigestView.swift
//  weftly
//
//  Created for unified agent architecture (PR #32)
//  Main Digest tab displaying AI-extracted items
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct DigestView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var authService: AuthService
    @StateObject private var viewModel: DigestViewModel

    init(authService: AuthService) {
        _authService = ObservedObject(initialValue: authService)
        _viewModel = StateObject(wrappedValue: DigestViewModel(authService: authService))
    }
    @Query(sort: \DigestEvent.date) private var events: [DigestEvent]
    @Query(sort: \DigestDeadline.dueDate) private var deadlines: [DigestDeadline]
    @Query(sort: \DigestPriorityMessage.timestamp, order: .reverse) private var priorityMessages: [DigestPriorityMessage]
    @Query(sort: \DigestRSVP.eventDate) private var rsvps: [DigestRSVP]
    @Query(sort: \DigestSuggestion.createdAt, order: .reverse) private var suggestions: [DigestSuggestion]
    
    var pendingEvents: [DigestEvent] { events.filter { $0.status == "pending" } }
    var pendingDeadlines: [DigestDeadline] { deadlines.filter { $0.status == "pending" } }
    var pendingRSVPs: [DigestRSVP] { rsvps.filter { $0.status == "pending" } }
    var pendingSuggestions: [DigestSuggestion] {
        let pending = suggestions.filter { $0.status == "pending" }
        print("🔍 DigestView: Total suggestions: \(suggestions.count), pending: \(pending.count)")
        for s in suggestions {
            print("   - \(s.type): \"\(s.suggestionDescription.prefix(50))...\" status=\(s.status) options=\(s.options.count)")
        }
        return pending
    }
    var pendingPriorityMessages: [DigestPriorityMessage] { priorityMessages.filter { $0.status == "pending" } }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("Loading…")
                            .padding(.bottom, 8)
                    }
                    // Proactive suggestions (top priority)
                    if !pendingSuggestions.isEmpty {
                        SuggestionsSection(suggestions: pendingSuggestions, viewModel: viewModel)
                    }
                    
                    // Priority messages
                    if !pendingPriorityMessages.isEmpty {
                        PriorityMessagesSection(messages: pendingPriorityMessages, viewModel: viewModel)
                    }
                    
                    // Calendar events
                    if !pendingEvents.isEmpty {
                        CalendarEventsSection(events: pendingEvents, viewModel: viewModel)
                    }
                    
                    // Deadlines
                    if !pendingDeadlines.isEmpty {
                        DeadlinesSection(deadlines: pendingDeadlines, viewModel: viewModel)
                    }
                    
                    // RSVPs
                    if !pendingRSVPs.isEmpty {
                        RSVPSection(rsvps: pendingRSVPs, viewModel: viewModel)
                    }
                    
                    // Empty state
                    if pendingEvents.isEmpty && pendingDeadlines.isEmpty && 
                       pendingPriorityMessages.isEmpty && pendingRSVPs.isEmpty && pendingSuggestions.isEmpty {
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
            viewModel.bootstrapIfNeeded(context: modelContext, authService: authService)
        }
        .onDisappear {
            viewModel.tearDown()
        }
    }
}

// MARK: - Section Views
// EventsSection is now CalendarEventsSection in dedicated file

struct SuggestionsSection: View {
    let suggestions: [DigestSuggestion]
    let viewModel: DigestViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 Suggestions")
                .font(.headline)
            
            ForEach(suggestions) { suggestion in
                SuggestionCard(suggestion: suggestion, viewModel: viewModel)
            }
        }
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

// Duplicate components moved to dedicated files; keep DigestView lean

// Duplicate components moved to dedicated files; keep DigestView lean

struct SuggestionCard: View {
    let suggestion: DigestSuggestion
    let viewModel: DigestViewModel
    @State private var selectedOption: String?
    @State private var isExpanded = false
    @State private var showAlternatives = false
    
    var isConflictResolution: Bool {
        suggestion.type == "conflict_resolution"
    }
    
    var body: some View {
        Button(action: {
            if isConflictResolution {
                showAlternatives = true
            } else {
                isExpanded.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: isConflictResolution ? "exclamationmark.triangle.fill" : "lightbulb.fill")
                        .foregroundStyle(isConflictResolution ? .orange : .blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isConflictResolution ? "Scheduling Conflict" : "Suggestion")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        Text(suggestion.suggestionDescription)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                    
                    Spacer()
                    
                    if isConflictResolution && !suggestion.options.isEmpty {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Quick dismiss button
                if !isConflictResolution {
                    Button(action: {
                        Task {
                            await viewModel.dismissSuggestion(suggestion)
                        }
                    }) {
                        Text("Dismiss")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isConflictResolution ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isConflictResolution ? Color.orange.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showAlternatives) {
            ConflictResolutionSheet(
                suggestion: suggestion,
                viewModel: viewModel,
                selectedOption: $selectedOption,
                isPresented: $showAlternatives
            )
        }
    }
}

struct ConflictResolutionSheet: View {
    let suggestion: DigestSuggestion
    let viewModel: DigestViewModel
    @Binding var selectedOption: String?
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Conflict description
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.title2)
                        
                        Text("Scheduling Conflict")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Text(suggestion.suggestionDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // Alternative times
                if !suggestion.options.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Here are alternative times:")
                            .font(.headline)
                        
                        ForEach(Array(suggestion.options.enumerated()), id: \.offset) { index, option in
                            Button(action: {
                                selectedOption = option
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedOption == option ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedOption == option ? .blue : .gray)
                                        .font(.title3)
                                    
                                    Text(option)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedOption == option ? Color.blue.opacity(0.15) : Color(.systemGray6))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No alternatives available",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("No alternative time slots were suggested.")
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        dismiss()
                        Task {
                            await viewModel.dismissSuggestion(suggestion)
                        }
                    }
                }
                
                if selectedOption != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Schedule") {
                            // TODO: Create event at selected time
                            dismiss()
                            Task {
                                await viewModel.dismissSuggestion(suggestion)
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
