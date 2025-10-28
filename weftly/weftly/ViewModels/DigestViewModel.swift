import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class DigestViewModel: ObservableObject {
    @Published var events: [DigestEvent] = []
    @Published var rsvps: [RSVPResponse] = []
    @Published var deadlines: [Deadline] = []
    @Published var priorityMessages: [DigestPriorityMessage] = []
    
    @Published var isLoading = false
    @Published var lastRefreshed: Date?
    @Published var errorMessage: String?
    
    private let aiService = AIService.shared
    private let firestoreService = FirestoreService()
    private var authService: AuthService
    private var conversationIds: [String] = []
    private var refreshTimer: Timer?
    private var listenersStarted = false
    
    init(authService: AuthService) {
        self.authService = authService
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
        
        print("📥 loadAllInsights(): refreshing sections")
        async let eventsTask: Void = loadEvents()
        async let rsvpsTask: Void = loadRSVPs()
        async let deadlinesTask: Void = loadDeadlines()
        async let priorityMessagesTask: Void = loadPriorityMessages()
        
        await eventsTask
        await rsvpsTask
        await deadlinesTask
        await priorityMessagesTask
        
        lastRefreshed = Date()
        isLoading = false
        print("✅ Digest load complete at \(lastRefreshed?.description ?? "nil")")
    }
    
    func bootstrapIfNeeded(context: ModelContext, authService: AuthService) {
        guard !listenersStarted else { return }
        guard let userId = authService.currentUser?.id else {
            print("❌ No current user for digest listeners")
            return
        }
        self.authService = authService
        listenersStarted = true
        Task {
            print("🟢 DigestViewModel init: kicking off initial load")
            await loadAllInsights()
            setupAutoRefresh()
        }
        DigestService.shared.startListening(userId: userId, context: context)
    }

    func tearDown() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        listenersStarted = false
        DigestService.shared.stopListening()
    }
    
    private func loadEvents() async {
        // Events are synced into SwiftData via DigestService; no-op here
    }
    
    private func loadRSVPs() async {
        // RSVPs are synced into SwiftData via DigestService; no-op here
    }
    
    private func loadDeadlines() async {
        // Deadlines are synced into SwiftData via DigestService; no-op here
    }
    
    // decisions removed from Digest UI per product direction
    
    private func loadConversationIds() async {
        guard let currentUserId = authService.currentUser?.id else {
            print("❌ No current user for loading conversation IDs")
            return
        }
        
        print("📡 Listening for conversation IDs for user \(currentUserId)")
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var hasResumed = false
            
            firestoreService.listenToConversations(userId: currentUserId) { [weak self] conversations in
                guard !hasResumed else { return }
                hasResumed = true
                
                self?.conversationIds = conversations.compactMap { $0.id }
                print("✅ Loaded \(conversations.count) conversation IDs for Digest")
                
                self?.firestoreService.removeConversationListener()
                continuation.resume()
            }
        }
    }
    
    func refresh(silent: Bool = false) async {
        if !silent {
            print("🔄 Manual digest refresh triggered")
            await loadAllInsights()
        } else {
            print("🔄 Silent digest refresh triggered")
            await loadConversationIds()
            
            async let eventsTask: Void = loadEvents()
            async let rsvpsTask: Void = loadRSVPs()
            async let deadlinesTask: Void = loadDeadlines()
            async let priorityMessagesTask: Void = loadPriorityMessages()
            
            await eventsTask
            await rsvpsTask
            await deadlinesTask
            await priorityMessagesTask
            
            lastRefreshed = Date()
            print("✅ Silent refresh complete at \(lastRefreshed?.description ?? "nil")")
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
    
    var totalPendingCount: Int {
        upcomingEventCount + pendingRSVPCount + overdueDeadlineCount
    }
    
    // MARK: - Event Actions
    func addEventToCalendar(_ event: DigestEvent) async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        do {
            // Add to iOS Calendar via EventKit
            let calendarService = CalendarService.shared
            _ = try await calendarService.addEvent(event)
            
            // Update Firestore to mark as addedToCalendar
            try await DigestService.shared.acceptEvent(event.id, userId: currentUserId)
            
            // Update local SwiftData model
            event.addedToCalendar = true
            event.status = "accepted"
        } catch {
            print("❌ Error adding event to calendar: \(error)")
            errorMessage = "Failed to add event to calendar: \(error.localizedDescription)"
        }
    }
    
    private func loadPriorityMessages() async {
        guard let currentUserId = authService.currentUser?.id else {
            print("❌ No current user for loading priority messages")
            return
        }
        
        print("🚀 loadPriorityMessages() with \(conversationIds.count) conversation IDs")
        do {
            let messages = try await firestoreService.getPriorityMessages(conversationIds: conversationIds, currentUserId: currentUserId)
            print("✅ Loaded \(messages.count) priority messages")
            // Map to DigestPriorityMessage lightweight view models if needed; for now, skip as FirestoreService returns domain objects
        } catch {
            print("❌ Error loading priority messages: \(error)")
        }
    }
    
    func dismissPriorityMessage(_ message: DigestPriorityMessage) async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        do {
            // Update Firestore via DigestService
            try await DigestService.shared.dismissPriorityMessage(message.id, userId: currentUserId)
            
            // Update local SwiftData
            message.status = "dismissed"
            
            print("✅ Priority message dismissed")
        } catch {
            print("❌ Error dismissing priority message: \(error)")
            errorMessage = "Failed to dismiss message"
        }
    }
    
    func dismissEvent(_ event: DigestEvent) async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        do {
            // Update Firestore to mark as dismissed
            try await DigestService.shared.dismissEvent(event.id, userId: currentUserId)
            
            // Update local SwiftData model
            event.status = "dismissed"
        } catch {
            print("❌ Error dismissing event: \(error)")
            errorMessage = "Failed to dismiss event"
        }
    }
    
    func dismissDeadline(_ deadline: DigestDeadline) async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        do {
            // Update Firestore via DigestService
            try await DigestService.shared.dismissDeadline(deadline.id, userId: currentUserId)
            
            // Update local SwiftData
            deadline.status = "dismissed"
            
            print("✅ Deadline dismissed")
        } catch {
            print("❌ Error dismissing deadline: \(error)")
            errorMessage = "Failed to dismiss deadline"
        }
    }
    
    // MARK: - Deadline Actions
    func markDeadlineComplete(_ deadline: DigestDeadline) async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        do {
            // Update Firestore via DigestService
            try await DigestService.shared.completeDeadline(deadline.id, userId: currentUserId)
            
            // Update local SwiftData
            deadline.completed = true
            deadline.status = "completed"
            
            print("✅ Deadline marked complete")
        } catch {
            print("❌ Error completing deadline: \(error)")
            errorMessage = "Failed to complete deadline"
        }
    }
    
    // MARK: - RSVP Actions
    func dismissRSVP(_ rsvp: DigestRSVP) async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        do {
            // Update Firestore via DigestService
            try await DigestService.shared.dismissRSVP(rsvp.id, userId: currentUserId)
            
            // Update local SwiftData
            rsvp.status = "dismissed"
            
            print("✅ RSVP dismissed")
        } catch {
            print("❌ Error dismissing RSVP: \(error)")
            errorMessage = "Failed to dismiss RSVP"
        }
    }
    
    // MARK: - Suggestion Actions
    func dismissSuggestion(_ suggestion: DigestSuggestion) async {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        do {
            // Update local SwiftData first (for immediate UI update)
            suggestion.status = "dismissed"
            
            // Update Firestore via DigestService
            try await DigestService.shared.dismissSuggestion(suggestion.id, userId: currentUserId)
            
            print("✅ Suggestion dismissed")
        } catch {
            print("❌ Error dismissing suggestion: \(error)")
            errorMessage = "Failed to dismiss suggestion"
        }
    }
}

