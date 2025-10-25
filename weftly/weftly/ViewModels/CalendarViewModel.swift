import Foundation
import SwiftUI
import Combine

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var extractedEvents: [ExtractedEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let aiService = AIService.shared
    private let calendarService = CalendarService.shared
    
    func loadEvents(for conversationId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            extractedEvents = try await aiService.getExtractedEvents(for: conversationId)
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
            print("❌ Calendar load error: \(error)")
        }
        
        isLoading = false
    }
    
    func addToCalendar(_ event: ExtractedEvent) async {
        do {
            _ = try await calendarService.addEvent(event)
            
            // Update event status
            if let index = extractedEvents.firstIndex(where: { $0.id == event.id }) {
                extractedEvents[index].addedToCalendar = true
            }
        } catch {
            errorMessage = "Failed to add event to calendar: \(error.localizedDescription)"
            print("❌ Calendar add error: \(error)")
        }
    }
    
    func deleteEvent(_ event: ExtractedEvent) async {
        extractedEvents.removeAll { $0.id == event.id }
        // TODO: Delete from Firestore
    }
}

