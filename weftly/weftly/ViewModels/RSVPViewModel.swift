import Foundation
import SwiftUI
import Combine

@MainActor
class RSVPViewModel: ObservableObject {
    @Published var activeRSVPs: [RSVPResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestoreService = FirestoreService()
    
    func loadRSVPs(for conversationId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let rsvps = try await firestoreService.getRSVPs(conversationId: conversationId)
            activeRSVPs = rsvps
        } catch {
            errorMessage = "Failed to load RSVPs: \(error.localizedDescription)"
            print("❌ RSVP load error: \(error)")
        }
        
        isLoading = false
    }
    
    func sendReminders(for eventId: String, conversationId: String) async {
        // TODO: agent-driven reminders
        print("📧 Sending RSVP reminders for event: \(eventId)")
    }
    
    func refreshRSVP(_ eventId: String, conversationId: String) async {
        await loadRSVPs(for: conversationId)
    }
}

