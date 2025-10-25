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
    
    init() {
        Task {
            await loadAllInsights()
        }
    }
    
    func loadAllInsights() async {
        isLoading = true
        errorMessage = nil
        
        // Load all sections in parallel
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
        // TODO: Load from all conversations
        // For now, empty list
        events = []
    }
    
    private func loadRSVPs() async {
        // TODO: Load from all conversations
        // For now, empty list
        rsvps = []
    }
    
    private func loadDeadlines() async {
        // TODO: Get current user ID and load their deadlines
        // For now, empty list
        deadlines = []
    }
    
    private func loadDecisions() async {
        // TODO: Load from all conversations
        // For now, empty list
        decisions = []
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

