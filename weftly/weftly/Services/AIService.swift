import Foundation
import SwiftData

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    
    private let functionsService = FunctionsService.shared
    private let calendarService = CalendarService.shared
    
    // Cache with 5-minute TTL
    private var eventCache: [String: (events: [ExtractedEvent], timestamp: Date)] = [:]
    private var rsvpCache: [String: (rsvp: RSVPResponse, timestamp: Date)] = [:]
    private var decisionCache: [String: (decisions: [AIDecision], timestamp: Date)] = [:]
    private let cacheTTL: TimeInterval = 300  // 5 minutes
    
    // Processing queue
    private var processingQueue: [Message] = []
    private var isProcessing = false
    
    @Published var isEnabled = true
    @Published var priorityDetectionEnabled = true
    @Published var calendarExtractionEnabled = true
    @Published var rsvpTrackingEnabled = true
    @Published var deadlineRemindersEnabled = true
    @Published var proactiveSuggestionsEnabled = true
    
    private init() {}
    
    // MARK: - Message Processing
    func processNewMessage(_ message: Message) async {
        guard isEnabled else { return }
        
        processingQueue.append(message)
        
        if !isProcessing {
            await processQueue()
        }
    }
    
    private func processQueue() async {
        isProcessing = true
        
        while !processingQueue.isEmpty {
            let message = processingQueue.removeFirst()
            
            // Run AI features in parallel
            async let calendarTask: Void = extractCalendarIfEnabled(message)
            async let deadlineTask: Void = extractDeadlinesIfEnabled(message)
            async let priorityTask: Void = detectPriorityIfEnabled(message)
            
            await calendarTask
            await deadlineTask
            await priorityTask
        }
        
        isProcessing = false
    }
    
    // MARK: - Calendar Extraction
    private func extractCalendarIfEnabled(_ message: Message) async {
        guard calendarExtractionEnabled, !message.text.isEmpty else { return }
        
        do {
            let events = try await functionsService.extractCalendarEvents(
                messageText: message.text,
                conversationId: message.conversationId,
                messageId: message.id
            )
            
            if !events.isEmpty {
                print("📅 Extracted \(events.count) calendar event(s) from message")
                // Store in Firestore automatically by the function
                // Invalidate cache
                eventCache.removeValue(forKey: message.conversationId)
            }
        } catch {
            print("⚠️ Calendar extraction failed: \(error.localizedDescription)")
        }
    }
    
    func getExtractedEvents(for conversationId: String) async throws -> [ExtractedEvent] {
        // Check cache
        if let cached = eventCache[conversationId],
           Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return cached.events
        }
        
        // Fetch from Firestore
        let events = try await FirestoreService.shared.getExtractedEvents(conversationId: conversationId)
        
        // Update cache
        eventCache[conversationId] = (events, Date())
        
        return events
    }
    
    // MARK: - Priority Detection
    private func detectPriorityIfEnabled(_ message: Message) async {
        guard priorityDetectionEnabled, !message.text.isEmpty else { return }
        
        do {
            let priority = try await functionsService.detectPriority(messageText: message.text)
            
            // Only update if confidence is high
            if priority.confidence > 0.75 {
                print("🚨 Priority detected: \(priority.level) (\(Int(priority.confidence * 100))%)")
                
                // Update message in Firestore
                try await FirestoreService.shared.updateMessagePriority(
                    messageId: message.id,
                    conversationId: message.conversationId,
                    priority: priority.level,
                    reason: priority.reason,
                    confidence: priority.confidence
                )
            }
        } catch {
            print("⚠️ Priority detection failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - RSVP Tracking
    func getRSVPs(for conversationId: String) async throws -> RSVPResponse? {
        guard rsvpTrackingEnabled else { return nil }
        
        // Check cache
        if let cached = rsvpCache[conversationId],
           Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return cached.rsvp
        }
        
        // Fetch from Functions
        do {
            let rsvp = try await functionsService.trackRSVP(conversationId: conversationId, eventId: nil)
            
            // Update cache
            rsvpCache[conversationId] = (rsvp, Date())
            
            return rsvp
        } catch {
            print("⚠️ RSVP tracking failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func refreshRSVP(conversationId: String, eventId: String) async throws -> RSVPResponse {
        let rsvp = try await functionsService.trackRSVP(conversationId: conversationId, eventId: eventId)
        
        // Update cache
        rsvpCache[conversationId] = (rsvp, Date())
        
        return rsvp
    }
    
    // MARK: - Decision Summarization
    func getDecisions(for conversationId: String, query: String? = nil) async throws -> [AIDecision] {
        // Check cache (only for queries without specific search term)
        if query == nil,
           let cached = decisionCache[conversationId],
           Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return cached.decisions
        }
        
        // Fetch from Functions
        let decisions = try await functionsService.summarizeDecisions(
            conversationId: conversationId,
            query: query
        )
        
        // Update cache (only if no query)
        if query == nil {
            decisionCache[conversationId] = (decisions, Date())
        }
        
        return decisions
    }
    
    // MARK: - Deadline Extraction
    private func extractDeadlinesIfEnabled(_ message: Message) async {
        guard deadlineRemindersEnabled, !message.text.isEmpty else { return }
        
        do {
            let deadlines = try await functionsService.extractDeadlines(
                messageText: message.text,
                conversationId: message.conversationId,
                messageId: message.id
            )
            
            if !deadlines.isEmpty {
                print("⏰ Extracted \(deadlines.count) deadline(s) from message")
                // Store in Firestore automatically by the function
            }
        } catch {
            print("⚠️ Deadline extraction failed: \(error.localizedDescription)")
        }
    }
    
    func getUserDeadlines(userId: String) async throws -> [Deadline] {
        try await FirestoreService.shared.getUserDeadlines(userId: userId)
    }
    
    // MARK: - Settings Management
    func togglePriorityDetection(enabled: Bool) async {
        priorityDetectionEnabled = enabled
        // Could save to UserDefaults or Firestore
        UserDefaults.standard.set(enabled, forKey: "priorityDetectionEnabled")
    }
    
    func toggleCalendarExtraction(enabled: Bool) async {
        calendarExtractionEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "calendarExtractionEnabled")
    }
    
    func toggleRSVPTracking(enabled: Bool) async {
        rsvpTrackingEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "rsvpTrackingEnabled")
    }
    
    func toggleDeadlineReminders(enabled: Bool) async {
        deadlineRemindersEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "deadlineRemindersEnabled")
    }
    
    func toggleProactiveSuggestions(enabled: Bool) async {
        proactiveSuggestionsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "proactiveSuggestionsEnabled")
    }
    
    // MARK: - Cache Management
    func clearCache() {
        eventCache.removeAll()
        rsvpCache.removeAll()
        decisionCache.removeAll()
        print("🗑️ AI service cache cleared")
    }
    
    func clearCacheForConversation(_ conversationId: String) {
        eventCache.removeValue(forKey: conversationId)
        rsvpCache.removeValue(forKey: conversationId)
        decisionCache.removeValue(forKey: conversationId)
    }
}

