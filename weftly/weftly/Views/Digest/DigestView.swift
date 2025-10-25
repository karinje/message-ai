import SwiftUI

struct DigestView: View {
    @StateObject private var viewModel: DigestViewModel
    
    init(authService: AuthService) {
        _viewModel = StateObject(wrappedValue: DigestViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.events.isEmpty && viewModel.rsvps.isEmpty &&
                   viewModel.deadlines.isEmpty && viewModel.decisions.isEmpty &&
                   viewModel.priorityMessages.isEmpty && !viewModel.isLoading {
                    // Empty State
                    VStack(spacing: 24) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue.gradient)
                        
                        Text("No insights yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start chatting and AI will automatically extract urgent messages, events, RSVPs, deadlines, and decisions from your conversations")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    // Content
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Priority Messages Section (show at top - most urgent)
                            if !viewModel.priorityMessages.isEmpty {
                                PriorityMessagesSection(messages: viewModel.priorityMessages)
                            }
                            
                            // Calendar Events Section
                            if !viewModel.events.isEmpty {
                                CalendarEventsSection(events: viewModel.events, viewModel: viewModel)
                            }
                            
                            // RSVPs Section
                            if !viewModel.rsvps.isEmpty {
                                RSVPSection(rsvps: viewModel.rsvps)
                            }
                            
                            // Deadlines Section
                            if !viewModel.deadlines.isEmpty {
                                DeadlinesSection(deadlines: viewModel.deadlines, viewModel: viewModel)
                            }
                            
                            // Decisions Section
                            if !viewModel.decisions.isEmpty {
                                DecisionsSection(decisions: viewModel.decisions)
                            }
                            
                            // Last refreshed
                            if let lastRefreshed = viewModel.lastRefreshed {
                                Text("Last updated \(lastRefreshed, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
                
                // Loading overlay
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView("Loading insights...")
                }
            }
            .navigationTitle("Digest")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.isLoading {
                        Button(action: {
                            Task {
                                await viewModel.refresh()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    DigestView(authService: AuthService())
}

