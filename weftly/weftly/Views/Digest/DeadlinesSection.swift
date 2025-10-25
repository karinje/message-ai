import SwiftUI

struct DeadlinesSection: View {
    let deadlines: [Deadline]
    @ObservedObject var viewModel: DigestViewModel
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "alarm")
                        .foregroundStyle(.red)
                    
                    Text("Deadlines")
                        .font(.headline)
                    
                    Spacer()
                    
                    if overdueCount > 0 {
                        Text("\(overdueCount) overdue")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    } else if incompleteCount > 0 {
                        Text("\(incompleteCount)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                // Group deadlines by urgency
                if !overdueDeadlines.isEmpty {
                    DeadlineGroup(title: "Overdue", deadlines: overdueDeadlines, viewModel: viewModel)
                }
                
                if !todayDeadlines.isEmpty {
                    DeadlineGroup(title: "Today", deadlines: todayDeadlines, viewModel: viewModel)
                }
                
                if !thisWeekDeadlines.isEmpty {
                    DeadlineGroup(title: "This Week", deadlines: thisWeekDeadlines, viewModel: viewModel)
                }
                
                if !laterDeadlines.isEmpty {
                    DeadlineGroup(title: "Later", deadlines: laterDeadlines, viewModel: viewModel)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    // MARK: - Grouped Deadlines
    var incompleteDeadlines: [Deadline] {
        deadlines.filter { !$0.completed }.sorted { $0.dueDate < $1.dueDate }
    }
    
    var overdueDeadlines: [Deadline] {
        incompleteDeadlines.filter { $0.isOverdue() }
    }
    
    var todayDeadlines: [Deadline] {
        incompleteDeadlines.filter { $0.isDueToday() }
    }
    
    var thisWeekDeadlines: [Deadline] {
        let calendar = Calendar.current
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        return incompleteDeadlines.filter {
            !$0.isDueToday() && !$0.isOverdue() && $0.dueDate < weekFromNow
        }
    }
    
    var laterDeadlines: [Deadline] {
        let calendar = Calendar.current
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        return incompleteDeadlines.filter {
            $0.dueDate >= weekFromNow
        }
    }
    
    var overdueCount: Int {
        overdueDeadlines.count
    }
    
    var incompleteCount: Int {
        incompleteDeadlines.count
    }
}

struct DeadlineGroup: View {
    let title: String
    let deadlines: [Deadline]
    @ObservedObject var viewModel: DigestViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            
            ForEach(deadlines) { deadline in
                DeadlineCardView(deadline: deadline, onComplete: {
                    Task {
                        await viewModel.markDeadlineComplete(deadline)
                    }
                })
            }
        }
    }
}

#Preview {
    DeadlinesSection(
        deadlines: [
            Deadline(
                task: "Bring cupcakes to school",
                dueDate: Date().addingTimeInterval(-3600),
                priority: .high,
                conversationId: "123",
                messageId: "456",
                confidence: 0.9
            ),
            Deadline(
                task: "Permission slip due",
                dueDate: Date().addingTimeInterval(86400),
                priority: .medium,
                conversationId: "123",
                messageId: "789",
                confidence: 0.85
            )
        ],
        viewModel: DigestViewModel()
    )
    .padding()
}

