import Foundation
import SwiftUI
import Combine

@MainActor
class DeadlineViewModel: ObservableObject {
    @Published var deadlines: [Deadline] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestoreService = FirestoreService()
    
    func loadDeadlines(for userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            deadlines = try await firestoreService.getUserDeadlines(userId: userId)
        } catch {
            errorMessage = "Failed to load deadlines: \(error.localizedDescription)"
            print("❌ Deadline load error: \(error)")
        }
        
        isLoading = false
    }
    
    func markComplete(_ deadline: Deadline) async {
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
    
    // MARK: - Computed Properties
    var overdueDeadlines: [Deadline] {
        deadlines.filter { $0.isOverdue() && !$0.completed }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    var todayDeadlines: [Deadline] {
        deadlines.filter { $0.isDueToday() && !$0.completed }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    var upcomingDeadlines: [Deadline] {
        let today = Date()
        return deadlines.filter {
            !$0.isOverdue() && !$0.isDueToday() && !$0.completed && $0.dueDate > today
        }
        .sorted { $0.dueDate < $1.dueDate }
    }
    
    var completedDeadlines: [Deadline] {
        deadlines.filter { $0.completed }
            .sorted { $0.dueDate > $1.dueDate }
    }
}

