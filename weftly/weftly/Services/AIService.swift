import Foundation
import SwiftData
import Combine
import FirebaseFunctions
import FirebaseAuth
import EventKit

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    
    private let functionsService = FunctionsService.shared
    private let calendarService = CalendarService.shared
    private let firestoreService = FirestoreService()
    
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
    // PR #31: New unified agent implementation
    func processNewMessage(_ message: Message, conversation: Conversation, context: ModelContext) async {
        guard isEnabled else { return }
        
        // 1. Check if AI indexing enabled for this conversation
        let descriptor = FetchDescriptor<LocalConversationState>(
            predicate: #Predicate { state in state.conversationId == (conversation.id ?? "") }
        )
        guard let state = try? context.fetch(descriptor).first,
              state.aiIndexingEnabled else {
            return // AI not enabled for this thread
        }
        
        // 2. Get recent messages from SwiftData
        let recentDescriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate { msg in msg.conversationId == (conversation.id ?? "") },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        var recentDescriptor2 = recentDescriptor
        recentDescriptor2.fetchLimit = 50
        
        let recentMessages = (try? context.fetch(recentDescriptor2).reversed()) ?? []
        
        // 3. Call Firebase Function
        let callable = Functions.functions().httpsCallable("processMessage")
        
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        var calendarEventsPayload: [[String: Any]] = []
        if let upcomingEvents = try? await calendarService.getUpcomingEvents(days: 14) {
            calendarEventsPayload = upcomingEvents.map { event in
                let start = event.startDate ?? Date()
                let end = event.endDate ?? start.addingTimeInterval(3600)
                return [
                    "id": event.eventIdentifier ?? UUID().uuidString,
                    "title": event.title ?? "Untitled",
                    "startDateTime": formatter.string(from: start),
                    "endDateTime": formatter.string(from: end),
                    "location": event.location ?? "",
                    "calendarTitle": event.calendar.title,
                    "source": "device_calendar"
                ]
            }
        }
        
        guard let conversationId = conversation.id else {
            print("⚠️ Missing conversation.id, skipping processMessage call")
            return
        }
        
        let requestData: [String: Any] = [
            "userId": (Auth.auth().currentUser?.uid) ?? "",
            "conversationId": conversationId,
            "newMessage": [
                "id": message.id ?? UUID().uuidString,
                "text": message.text,
                "senderId": message.senderId,
                "senderName": message.senderName,
                "timestamp": Int(message.timestamp.timeIntervalSince1970 * 1000)
            ],
            "recentMessages": recentMessages.map { [
                "id": $0.id,
                "text": $0.text,
                "senderId": $0.senderId,
                "senderName": $0.senderName,
                "timestamp": Int($0.timestamp.timeIntervalSince1970 * 1000)
            ]},
            "calendarEvents": calendarEventsPayload
        ]
        
        do {
            _ = try await callable.call(requestData)
            
            // 4. Update last processed
            state.lastProcessedMessageId = message.id
            state.lastProcessedAt = Date()
            try? context.save()
            
            print("✅ Message processed by unified agent")
        } catch {
            print("❌ Error processing message: \(error.localizedDescription)")
        }
    }
    
    // PR #25: Commented out - will be replaced by unified agent
    // private func processQueue() async {
    //     isProcessing = true
    //     
    //     while !processingQueue.isEmpty {
    //         let message = processingQueue.removeFirst()
    //         
    //         // Run AI features in parallel
    //         async let calendarTask: Void = extractCalendarIfEnabled(message)
    //         async let deadlineTask: Void = extractDeadlinesIfEnabled(message)
    //         async let priorityTask: Void = detectPriorityIfEnabled(message)
    //         
    //         await calendarTask
    //         await deadlineTask
    //         await priorityTask
    //     }
    //     
    //     isProcessing = false
    // }
    
    // MARK: - Calendar Extraction
    // PR #25: Commented out - old implementation will be replaced by unified agent
    // private func extractCalendarIfEnabled(_ message: Message) async {
    //     guard calendarExtractionEnabled, !message.text.isEmpty else { return }
    //     
    //     do {
    //         let events = try await functionsService.extractCalendarEvents(
    //             messageText: message.text,
    //             conversationId: message.conversationId,
    //             messageId: message.id ?? UUID().uuidString
    //         )
    //         
    //         if !events.isEmpty {
    //             print("📅 Extracted \(events.count) calendar event(s) from message")
    //             // Store in Firestore automatically by the function
    //             // Invalidate cache
    //             eventCache.removeValue(forKey: message.conversationId)
    //         }
    //     } catch {
    //         print("⚠️ Calendar extraction failed: \(error.localizedDescription)")
    //     }
    // }
    
    // Removed legacy getExtractedEvents(cache-based). Digest events now flow via DigestService
    
    // MARK: - Priority Detection
    // PR #25: Commented out - old implementation will be replaced by unified agent
    // private func detectPriorityIfEnabled(_ message: Message) async {
    //     guard priorityDetectionEnabled, !message.text.isEmpty else { return }
    //     
    //     do {
    //         let priority = try await functionsService.detectPriority(messageText: message.text)
    //         
    //         // Only update if confidence is high
    //         if priority.confidence > 0.75 {
    //             print("🚨 Priority detected: \(priority.level) (\(Int(priority.confidence * 100))%)")
    //             
    //             // Update message in Firestore
    //             try await firestoreService.updateMessagePriority(
    //                 messageId: message.id ?? UUID().uuidString,
    //                 conversationId: message.conversationId,
    //                 priority: priority.level,
    //                 reason: priority.reason,
    //                 confidence: priority.confidence
    //             )
    //         }
    //     } catch {
    //         print("⚠️ Priority detection failed: \(error.localizedDescription)")
    //     }
    // }
    
    // MARK: - Deadline Extraction
    // PR #25: Commented out - old implementation will be replaced by unified agent
    // private func extractDeadlinesIfEnabled(_ message: Message) async {
    //     guard deadlineRemindersEnabled, !message.text.isEmpty else { return }
    //     
    //     do {
    //         let deadlines = try await functionsService.extractDeadlines(
    //             messageText: message.text,
    //             conversationId: message.conversationId,
    //             messageId: message.id ?? UUID().uuidString
    //         )
    //         
    //         if !deadlines.isEmpty {
    //             print("⏰ Extracted \(deadlines.count) deadline(s) from message")
    //             // Store in Firestore automatically by the function
    //         }
    //     } catch {
    //         print("⚠️ Deadline extraction failed: \(error.localizedDescription)")
    //     }
    // }
    
    func getUserDeadlines(userId: String) async throws -> [Deadline] {
        try await firestoreService.getUserDeadlines(userId: userId)
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
    
    // MARK: - Cache Management (legacy no-ops)
    func clearCache() { print("🗑️ AI service cache cleared") }
    func clearCacheForConversation(_ conversationId: String) { }
}

