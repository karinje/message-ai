import Foundation
import SwiftUI
import Combine

@MainActor
class RSVPViewModel: ObservableObject {
    @Published var activeRSVPs: [RSVPResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let functionsService = FunctionsService.shared
    
    func loadRSVPs(for conversationId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let rsvp = try await functionsService.trackRSVP(conversationId: conversationId, eventId: nil)
            activeRSVPs = [rsvp]
        } catch {
            errorMessage = "Failed to load RSVPs: \(error.localizedDescription)"
            print("❌ RSVP load error: \(error)")
        }
        
        isLoading = false
    }
    
    func sendReminders(for eventId: String, conversationId: String) async {
        // TODO: Call Firebase Function to send reminders
        print("📧 Sending RSVP reminders for event: \(eventId)")
    }
    
    func refreshRSVP(_ eventId: String, conversationId: String) async {
        isLoading = true
        
        do {
            let rsvp = try await functionsService.trackRSVP(conversationId: conversationId, eventId: eventId)
            
            // Update in list
            if let index = activeRSVPs.firstIndex(where: { $0.id == eventId }) {
                activeRSVPs[index] = rsvp
            } else {
                activeRSVPs.append(rsvp)
            }
        } catch {
            errorMessage = "Failed to refresh RSVP: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

