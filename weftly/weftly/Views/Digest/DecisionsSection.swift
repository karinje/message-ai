import SwiftUI

struct DecisionsSection: View {
    let decisions: [AIDecision]
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(.yellow)
                    
                    Text("Group Decisions")
                        .font(.headline)
                    
                    Spacer()
                    
                    if recentDecisions.count > 0 {
                        Text("\(recentDecisions.count)")
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
                ForEach(recentDecisions) { decision in
                    DecisionCard(decision: decision)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    var recentDecisions: [AIDecision] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return decisions
            .filter { $0.timestamp > sevenDaysAgo }
            .sorted { $0.timestamp > $1.timestamp }
    }
}

struct DecisionCard: View {
    let decision: AIDecision
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Topic
            Text(decision.topic)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Decision
            Text(decision.decision)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Participants
            HStack(spacing: 4) {
                Image(systemName: "person.2")
                    .font(.caption2)
                Text("\(decision.participantCount()) participants agreed")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            
            // Timestamp
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(decision.timestamp, style: .relative)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            
            // Confidence
            if decision.confidence < 1.0 {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("\(Int(decision.confidence * 100))% confident")
                        .font(.caption2)
                }
                .foregroundStyle(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    DecisionsSection(decisions: [
        AIDecision(
            topic: "Party location",
            decision: "Pizza place on Friday at 6pm",
            participants: ["user1", "user2", "user3"],
            confidence: 0.9,
            timestamp: Date().addingTimeInterval(-7200),
            conversationId: "123"
        ),
        AIDecision(
            topic: "Carpool schedule",
            decision: "Parents take turns every week starting Monday",
            participants: ["user1", "user2"],
            confidence: 0.85,
            timestamp: Date().addingTimeInterval(-3600),
            conversationId: "456"
        )
    ])
    .padding()
}

