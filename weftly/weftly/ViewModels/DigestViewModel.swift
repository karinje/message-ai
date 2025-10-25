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
    @Published var priorityMessages: [PriorityMessage] = []
    
    @Published var isLoading = false
    @Published var lastRefreshed: Date?
    @Published var errorMessage: String?
    
    private let aiService = AIService.shared
    private let firestoreService = FirestoreService()
    private let authService: AuthService
    private var conversationIds: [String] = []
    private var refreshTimer: Timer?
    
    init(authService: AuthService) {
        self.authService = authService
        Task {
            await loadAllInsights()
            setupAutoRefresh()
        }
    }
    
    private func setupAutoRefresh() {
        // Auto-refresh every 30 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh(silent: true)
            }
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
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
        async let priorityMessagesTask = loadPriorityMessages()
        
        await eventsTask
        await rsvpsTask
        await deadlinesTask
        await decisionsTask
        await priorityMessagesTask
        
        lastRefreshed = Date()
        isLoading = false
    }
    
    private func loadEvents() async {
        guard let currentUserId = authService.currentUser?.id else {
            print("❌ No current user for loading events")
            return
        }
        
        var allEvents: [ExtractedEvent] = []
        
        // Fetch events from each conversation (filtered by current user)
        for conversationId in conversationIds {
            do {
                let conversationEvents = try await firestoreService.getExtractedEvents(conversationId: conversationId, currentUserId: currentUserId)
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
    
    func refresh(silent: Bool = false) async {
        if !silent {
            await loadAllInsights()
        } else {
            // Silent refresh - don't show loading indicator
            await loadConversationIds()
            
            async let eventsTask = loadEvents()
            async let rsvpsTask = loadRSVPs()
            async let deadlinesTask = loadDeadlines()
            async let decisionsTask = loadDecisions()
            async let priorityMessagesTask = loadPriorityMessages()
            
            await eventsTask
            await rsvpsTask
            await deadlinesTask
            await decisionsTask
            await priorityMessagesTask
            
            lastRefreshed = Date()
        }
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
    
    private func loadPriorityMessages() async {
        guard let currentUserId = authService.currentUser?.id else {
            print("❌ No current user for loading priority messages")
            return
        }
        
        print("🚀 loadPriorityMessages() called with \(conversationIds.count) conversation IDs")
        do {
            let messages = try await firestoreService.getPriorityMessages(conversationIds: conversationIds, currentUserId: currentUserId)
            print("✅ Loaded \(messages.count) priority messages")
            self.priorityMessages = messages
        } catch {
            print("❌ Error loading priority messages: \(error)")
        }
    }
    
    func dismissPriorityMessage(_ message: PriorityMessage) async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        do {
            try await firestoreService.dismissPriorityMessage(
                messageId: message.id,
                conversationId: message.conversationId,
                userId: currentUserId
            )
            // Remove from local list
            priorityMessages.removeAll { $0.id == message.id }
        } catch {
            print("❌ Error dismissing priority message: \(error)")
            errorMessage = "Failed to dismiss message"
        }
    }
    
    func dismissEvent(_ event: ExtractedEvent) async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        do {
            try await firestoreService.dismissEvent(
                eventId: event.id,
                conversationId: event.conversationId,
                userId: currentUserId
            )
            // Remove from local list
            events.removeAll { $0.id == event.id }
        } catch {
            print("❌ Error dismissing event: \(error)")
            errorMessage = "Failed to dismiss event"
        }
    }
    
    func dismissDeadline(_ deadline: Deadline) async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        do {
            try await firestoreService.dismissDeadline(
                deadlineId: deadline.id,
                userId: currentUserId
            )
            // Remove from local list
            deadlines.removeAll { $0.id == deadline.id }
        } catch {
            print("❌ Error dismissing deadline: \(error)")
            errorMessage = "Failed to dismiss deadline"
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

