import Foundation
import EventKit

enum CalendarError: Error {
    case accessDenied
    case eventNotFound
    case saveFailed
    case deleteFailed
    
    var localizedDescription: String {
        switch self {
        case .accessDenied:
            return "Calendar access denied. Please enable in Settings."
        case .eventNotFound:
            return "Event not found in calendar"
        case .saveFailed:
            return "Failed to save event to calendar"
        case .deleteFailed:
            return "Failed to delete event from calendar"
        }
    }
}

@MainActor
class CalendarService: ObservableObject {
    static let shared = CalendarService()
    
    private let eventStore = EKEventStore()
    @Published var hasCalendarAccess = false
    
    private init() {
        Task {
            await checkCalendarAccess()
        }
    }
    
    // MARK: - Permission Management
    func requestCalendarAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    self.hasCalendarAccess = granted
                }
                return granted
            } catch {
                print("❌ Calendar access request failed: \(error.localizedDescription)")
                throw CalendarError.accessDenied
            }
        } else {
            // Fallback for iOS 16 and earlier
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    Task { @MainActor in
                        self.hasCalendarAccess = granted
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    func checkCalendarAccess() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        let granted = status == .fullAccess || status == .authorized
        
        await MainActor.run {
            self.hasCalendarAccess = granted
        }
    }
    
    // MARK: - Event Management
    func addEvent(_ extractedEvent: ExtractedEvent) async throws -> String {
        // Request access if not granted
        if !hasCalendarAccess {
            let granted = try await requestCalendarAccess()
            if !granted {
                throw CalendarError.accessDenied
            }
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = extractedEvent.title
        event.startDate = extractedEvent.date
        event.endDate = extractedEvent.date.addingTimeInterval(3600)  // 1 hour default
        
        if let location = extractedEvent.location {
            event.location = location
        }
        
        // Add notes with source info
        event.notes = "Added from Weftly\nConfidence: \(Int(extractedEvent.confidence * 100))%\nMessage ID: \(extractedEvent.messageId)"
        
        // Use default calendar
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Save event
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ Event saved to calendar: \(event.title ?? "Untitled")")
            return event.eventIdentifier
        } catch {
            print("❌ Failed to save event: \(error.localizedDescription)")
            throw CalendarError.saveFailed
        }
    }
    
    func removeEvent(eventId: String) async throws {
        guard hasCalendarAccess else {
            throw CalendarError.accessDenied
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            print("✅ Event removed from calendar")
        } catch {
            print("❌ Failed to remove event: \(error.localizedDescription)")
            throw CalendarError.deleteFailed
        }
    }
    
    func getUpcomingEvents(days: Int = 30) async throws -> [EKEvent] {
        guard hasCalendarAccess else {
            throw CalendarError.accessDenied
        }
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate) ?? startDate
        
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        
        let events = eventStore.events(matching: predicate)
        return events.sorted { $0.startDate < $1.startDate }
    }
    
    func getEventsForDate(_ date: Date) async throws -> [EKEvent] {
        guard hasCalendarAccess else {
            throw CalendarError.accessDenied
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: calendars)
        
        let events = eventStore.events(matching: predicate)
        return events.sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - Conflict Detection
    func hasConflict(at date: Date, duration: TimeInterval = 3600) async throws -> Bool {
        let events = try await getEventsForDate(date)
        let endDate = date.addingTimeInterval(duration)
        
        return events.contains { event in
            // Check if event overlaps with proposed time
            let eventStart = event.startDate
            let eventEnd = event.endDate
            
            return (date >= eventStart && date < eventEnd) ||
                   (endDate > eventStart && endDate <= eventEnd) ||
                   (date <= eventStart && endDate >= eventEnd)
        }
    }
    
    func getConflictingEvents(at date: Date, duration: TimeInterval = 3600) async throws -> [EKEvent] {
        let events = try await getEventsForDate(date)
        let endDate = date.addingTimeInterval(duration)
        
        return events.filter { event in
            let eventStart = event.startDate
            let eventEnd = event.endDate
            
            return (date >= eventStart && date < eventEnd) ||
                   (endDate > eventStart && endDate <= eventEnd) ||
                   (date <= eventStart && endDate >= eventEnd)
        }
    }
}

