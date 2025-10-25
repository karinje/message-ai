import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class DigestViewModel: ObservableObject {
    @Published var events: [ExtractedEvent] = []
    @Published var rsvps: [RSVPResponse] = []
    @Published var deadlines: [Deadline] = []
    @Published var decisions: [AIDecision] = []
    
    @Published var isLoading = false
    @Published var lastRefreshed: Date?
    @Published var errorMessage: String?
    
    private let aiService = AIService.shared
    private let firestoreService = FirestoreService()
    private let authService: AuthService
    private var conversationIds: [String] = []
    
    init(authService: AuthService) {
        self.authService = authService
        Task {
            await loadAllInsights()
        }
    }
    
    func loadAllInsights() async {
        isLoading = true
        errorMessage = nil
        
        // Load conversation IDs FIRST (once) to avoid race conditions
        await loadConversationIds()
        
        // Now load all sections in parallel
        async let eventsTask = loadEvents()
        async let rsvpsTask = loadRSVPs()
        async let deadlinesTask = loadDeadlines()
        async let decisionsTask = loadDecisions()
        
        await eventsTask
        await rsvpsTask
        await deadlinesTask
        await decisionsTask
        
        lastRefreshed = Date()
        isLoading = false
    }
    
    private func loadEvents() async {
        guard let currentUserId = authService.currentUser?.id else {
            print("❌ No current user for loading events")
            return
        }
        
        var allEvents: [ExtractedEvent] = []
        
        // Fetch events from each conversation
        for conversationId in conversationIds {
            do {
                let conversationEvents = try await aiService.getExtractedEvents(for: conversationId)
                allEvents.append(contentsOf: conversationEvents)
            } catch {
                print("❌ Error loading events from conversation \(conversationId): \(error)")
            }
        }
        
        // Sort by date (upcoming first)
        events = allEvents.sorted { $0.date < $1.date }
        print("✅ Loaded \(events.count) calendar events")
    }
    
    private func loadRSVPs() async {
        guard let currentUserId = authService.currentUser?.id else {
            print("❌ No current user for loading RSVPs")
            return
        }
        
        var allRSVPs: [RSVPResponse] = []
        
        for conversationId in conversationIds {
            do {
                if let rsvp = try await aiService.getRSVPs(for: conversationId) {
                    allRSVPs.append(rsvp)
                }
            } catch {
                print("❌ Error loading RSVPs from conversation \(conversationId): \(error)")
            }
        }
        
        rsvps = allRSVPs.sorted { $0.eventDate < $1.eventDate }
        print("✅ Loaded \(rsvps.count) RSVPs")
    }
    
    private func loadDeadlines() async {
        guard let currentUserId = authService.currentUser?.id else {
            print("❌ No current user for loading deadlines")
            return
        }
        
        do {
            deadlines = try await aiService.getUserDeadlines(userId: currentUserId)
            deadlines.sort { $0.dueDate < $1.dueDate }
            print("✅ Loaded \(deadlines.count) deadlines")
        } catch {
            print("❌ Error loading deadlines: \(error)")
        }
    }
    
    private func loadDecisions() async {
        guard let currentUserId = authService.currentUser?.id else {
            print("❌ No current user for loading decisions")
            return
        }
        
        var allDecisions: [AIDecision] = []
        
        for conversationId in conversationIds {
            do {
                let conversationDecisions = try await aiService.getDecisions(for: conversationId)
                allDecisions.append(contentsOf: conversationDecisions)
            } catch {
                print("❌ Error loading decisions from conversation \(conversationId): \(error)")
            }
        }
        
        decisions = allDecisions.sorted { $0.timestamp > $1.timestamp }
        print("✅ Loaded \(decisions.count) decisions")
    }
    
    private func loadConversationIds() async {
        guard let currentUserId = authService.currentUser?.id else {
            print("❌ No current user for loading conversation IDs")
            return
        }
        
        // Use a one-shot listener approach with Task
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var hasResumed = false
            
            firestoreService.listenToConversations(userId: currentUserId) { [weak self] conversations in
                guard !hasResumed else { return } // Prevent multiple resumes
                hasResumed = true
                
                self?.conversationIds = conversations.compactMap { $0.id }
                print("✅ Loaded \(conversations.count) conversation IDs for Digest")
                
                // Remove listener immediately
                self?.firestoreService.removeConversationListener()
                
                continuation.resume()
            }
        }
    }
    
    func refresh() async {
        await loadAllInsights()
    }
    
    // MARK: - Computed Properties
    var upcomingEventCount: Int {
        events.filter { $0.date > Date() }.count
    }
    
    var pendingRSVPCount: Int {
        rsvps.reduce(0) { $0 + $1.noReplyCount() }
    }
    
    var overdueDeadlineCount: Int {
        deadlines.filter { $0.isOverdue() }.count
    }
    
    var recentDecisionCount: Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return decisions.filter { $0.timestamp > sevenDaysAgo }.count
    }
    
    var totalPendingCount: Int {
        upcomingEventCount + pendingRSVPCount + overdueDeadlineCount + recentDecisionCount
    }
    
    // MARK: - Event Actions
    func addEventToCalendar(_ event: ExtractedEvent) async {
        do {
            let calendarService = CalendarService.shared
            _ = try await calendarService.addEvent(event)
            
            // Update event status
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index].addedToCalendar = true
            }
        } catch {
            errorMessage = "Failed to add event to calendar: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Deadline Actions
    func markDeadlineComplete(_ deadline: Deadline) async {
        deadline.completed = true
        if let index = deadlines.firstIndex(where: { $0.id == deadline.id }) {
            deadlines[index] = deadline
        }
        
        // TODO: Update in Firestore
    }
    
    func deleteDeadline(_ deadline: Deadline) async {
        deadlines.removeAll { $0.id == deadline.id }
        // TODO: Delete from Firestore
    }
}

