import SwiftUI

struct RSVPSection: View {
    let rsvps: [RSVPResponse]
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "hand.raised")
                        .foregroundStyle(.orange)
                    
                    Text("Pending RSVPs")
                        .font(.headline)
                    
                    Spacer()
                    
                    if pendingCount > 0 {
                        Text("\(pendingCount)")
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
                ForEach(rsvps) { rsvp in
                    RSVPCard(rsvp: rsvp)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    var pendingCount: Int {
        rsvps.reduce(0) { $0 + $1.noReplyCount() }
    }
}

struct RSVPCard: View {
    let rsvp: RSVPResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event info
            VStack(alignment: .leading, spacing: 4) {
                Text(rsvp.eventTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(rsvp.eventDate, style: .date)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            // RSVP Summary
            HStack(spacing: 16) {
                RSVPStatusCount(count: rsvp.yesCount(), label: "Yes", color: .green)
                RSVPStatusCount(count: rsvp.maybeCount(), label: "Maybe", color: .orange)
                RSVPStatusCount(count: rsvp.noCount(), label: "No", color: .red)
                RSVPStatusCount(count: rsvp.noReplyCount(), label: "No Reply", color: .gray)
            }
            .font(.caption)
            
            // Progress bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    if rsvp.yesCount() > 0 {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geometry.size.width * (Double(rsvp.yesCount()) / Double(rsvp.totalParticipants)))
                    }
                    if rsvp.maybeCount() > 0 {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: geometry.size.width * (Double(rsvp.maybeCount()) / Double(rsvp.totalParticipants)))
                    }
                    if rsvp.noCount() > 0 {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: geometry.size.width * (Double(rsvp.noCount()) / Double(rsvp.totalParticipants)))
                    }
                    if rsvp.noReplyCount() > 0 {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: geometry.size.width * (Double(rsvp.noReplyCount()) / Double(rsvp.totalParticipants)))
                    }
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())
            
            // Response rate
            Text("\(Int(rsvp.percentageResponded()))% responded")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct RSVPStatusCount: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    RSVPSection(rsvps: [
        RSVPResponse(
            eventTitle: "Birthday party",
            eventDate: Date().addingTimeInterval(86400),
            conversationId: "123",
            responses: [
                "user1": UserRSVP(status: .yes, respondedAt: Date()),
                "user2": UserRSVP(status: .yes, respondedAt: Date()),
                "user3": UserRSVP(status: .maybe, respondedAt: Date()),
                "user4": UserRSVP(status: .noReply)
            ],
            totalParticipants: 4,
            messageId: "456"
        )
    ])
    .padding()
}

