import SwiftUI

struct RSVPSection: View {
    let rsvps: [DigestRSVP]
    let viewModel: DigestViewModel
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
                    
                    Text("\(rsvps.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                ForEach(rsvps) { rsvp in
                    DigestRSVPCard(rsvp: rsvp, viewModel: viewModel)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct DigestRSVPCard: View {
    let rsvp: DigestRSVP
    let viewModel: DigestViewModel
    @State private var showDetails = false
    
    // Parse responses
    var yesResponses: [(String, RSVPResponseData)] {
        rsvp.responses.filter { $0.value.response == "yes" }.sorted { $0.key < $1.key }
    }
    
    var noResponses: [(String, RSVPResponseData)] {
        rsvp.responses.filter { $0.value.response == "no" }.sorted { $0.key < $1.key }
    }
    
    var maybeResponses: [(String, RSVPResponseData)] {
        rsvp.responses.filter { $0.value.response == "maybe" }.sorted { $0.key < $1.key }
    }
    
    var totalResponded: Int {
        rsvp.responses.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with dismiss button
            HStack(alignment: .top) {
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
                
                Spacer()
                
                // Dismiss button
                Button(action: {
                    Task {
                        await viewModel.dismissRSVP(rsvp)
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Host indicator
            HStack(spacing: 4) {
                Image(systemName: rsvp.isHost ? "star.fill" : "person.2.fill")
                    .font(.caption2)
                Text(rsvp.isHost ? "You are hosting" : "Shared event")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            
            // Response summary
            if !rsvp.responses.isEmpty {
                HStack(spacing: 16) {
                    // Yes count
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("\(yesResponses.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    // No count
                    if !noResponses.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                            Text("\(noResponses.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    // Maybe count
                    if !maybeResponses.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("\(maybeResponses.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Spacer()
                    
                    // Show/hide details button
                    Button(action: { showDetails.toggle() }) {
                        Text(showDetails ? "Hide" : "Details")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                
                // Detailed responses
                if showDetails {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Yes responses
                        if !yesResponses.isEmpty {
                            ResponseGroup(title: "Coming", responses: yesResponses, color: .green)
                        }
                        
                        // Maybe responses
                        if !maybeResponses.isEmpty {
                            ResponseGroup(title: "Maybe", responses: maybeResponses, color: .orange)
                        }
                        
                        // No responses
                        if !noResponses.isEmpty {
                            ResponseGroup(title: "Can't Make It", responses: noResponses, color: .red)
                        }
                    }
                }
            } else {
                // No responses yet
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("No responses yet")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ResponseGroup: View {
    let title: String
    let responses: [(String, RSVPResponseData)]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            
            ForEach(Array(responses.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    Text("•")
                        .foregroundStyle(color)
                    Text(item.0) // Name/userId
                        .font(.caption)
                    
                    if let guestCount = item.1.guestCount, guestCount > 1 {
                        Text("(+\(guestCount - 1))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let note = item.1.note, !note.isEmpty {
                        Text("- \(note)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

//#Preview { /* Preview omitted while models stabilize */ // }

