import SwiftUI

struct DeadlinesSection: View {
    let deadlines: [DigestDeadline]
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
    var incompleteDeadlines: [DigestDeadline] {
        deadlines.filter { !$0.completed }.sorted { $0.dueDate < $1.dueDate }
    }
    
    var overdueDeadlines: [DigestDeadline] {
        incompleteDeadlines.filter { $0.dueDate < Date() }
    }
    
    var todayDeadlines: [DigestDeadline] {
        incompleteDeadlines.filter { Calendar.current.isDateInToday($0.dueDate) }
    }
    
    var thisWeekDeadlines: [DigestDeadline] {
        let calendar = Calendar.current
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        return incompleteDeadlines.filter {
            !Calendar.current.isDateInToday($0.dueDate) && $0.dueDate < weekFromNow
        }
    }
    
    var laterDeadlines: [DigestDeadline] {
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return incompleteDeadlines.filter { $0.dueDate >= weekFromNow }
    }
    
    var overdueCount: Int { overdueDeadlines.count }
    var incompleteCount: Int { incompleteDeadlines.count }
}

struct DeadlineGroup: View {
    let title: String
    let deadlines: [DigestDeadline]
    @ObservedObject var viewModel: DigestViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            
            ForEach(deadlines) { deadline in
                DigestDeadlineCard(deadline: deadline) {
                    Task {
                        await viewModel.markDeadlineComplete(deadline)
                    }
                } onDismiss: {
                    Task {
                        await viewModel.dismissDeadline(deadline)
                    }
                }
            }
        }
    }
}

struct DigestDeadlineCard: View {
    let deadline: DigestDeadline
    let onComplete: () -> Void
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onComplete) {
                Image(systemName: deadline.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(deadline.completed ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deadline.task)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .strikethrough(deadline.completed)
                    .foregroundStyle(deadline.completed ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    if deadline.dueDate < Date() {
                        Text("Overdue")
                            .foregroundStyle(.red)
                    } else if Calendar.current.isDateInToday(deadline.dueDate) {
                        Text("Due today")
                            .foregroundStyle(.orange)
                    } else {
                        Text(deadline.dueDate, style: .date)
                    }
                }
                .font(.caption)
                .foregroundStyle(deadline.dueDate < Date() ? .red : .secondary)
            }
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(deadline.dueDate < Date() ? Color.red.opacity(0.1) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

//#Preview { /* Preview removed to avoid referencing mismatched models */ // }

