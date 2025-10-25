import SwiftUI

struct DeadlineCardView: View {
    let deadline: Deadline
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority color strip
            Rectangle()
                .fill(priorityColor)
                .frame(width: 4)
            
            // Checkbox
            Button(action: onComplete) {
                Image(systemName: deadline.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(deadline.completed ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            // Task details
            VStack(alignment: .leading, spacing: 4) {
                Text(deadline.task)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .strikethrough(deadline.completed)
                    .foregroundStyle(deadline.completed ? .secondary : .primary)
                
                HStack(spacing: 12) {
                    // Due date
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        if deadline.isOverdue() {
                            Text("Overdue")
                                .foregroundStyle(.red)
                        } else if deadline.isDueToday() {
                            Text("Due today")
                                .foregroundStyle(.orange)
                        } else if deadline.isDueTomorrow() {
                            Text("Due tomorrow")
                                .foregroundStyle(.blue)
                        } else {
                            Text(deadline.dueDate, style: .date)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(deadline.isOverdue() ? .red : .secondary)
                    
                    // Priority badge
                    PriorityBadge(priority: deadline.priorityEnum)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(deadline.isOverdue() ? Color.red.opacity(0.1) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    var priorityColor: Color {
        switch deadline.priorityEnum {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct PriorityBadge: View {
    let priority: DeadlinePriority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundStyle(textColor)
            .clipShape(Capsule())
    }
    
    var backgroundColor: Color {
        switch priority {
        case .high: return .red.opacity(0.2)
        case .medium: return .orange.opacity(0.2)
        case .low: return .blue.opacity(0.2)
        }
    }
    
    var textColor: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        DeadlineCardView(
            deadline: Deadline(
                task: "Bring cupcakes to school",
                dueDate: Date().addingTimeInterval(-3600),
                priority: .high,
                conversationId: "123",
                messageId: "456",
                confidence: 0.9
            ),
            onComplete: {}
        )
        
        DeadlineCardView(
            deadline: Deadline(
                task: "Permission slip due",
                dueDate: Date().addingTimeInterval(86400),
                priority: .medium,
                conversationId: "123",
                messageId: "789",
                confidence: 0.85
            ),
            onComplete: {}
        )
        
        DeadlineCardView(
            deadline: Deadline(
                task: "Completed task",
                dueDate: Date().addingTimeInterval(86400),
                priority: .low,
                conversationId: "123",
                messageId: "abc",
                completed: true,
                confidence: 0.95
            ),
            onComplete: {}
        )
    }
    .padding()
}

