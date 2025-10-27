import SwiftUI

struct EventCardView: View {
    let event: DigestEvent
    let onAddToCalendar: () -> Void
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Date indicator
            VStack(spacing: 2) {
                Text(event.date, format: .dateTime.month(.abbreviated))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Text(event.date, format: .dateTime.day())
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .frame(width: 50)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    if let time = event.time, !time.isEmpty {
                        Text(time)
                            .font(.caption)
                    } else {
                        Text(event.date, style: .time)
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
                
                if let location = event.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                // Confidence indicator
                if event.confidence < 1.0 {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("\(Int(event.confidence * 100))% confident")
                            .font(.caption2)
                    }
                    .foregroundStyle(.blue)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                // Add to calendar button
                if !event.addedToCalendar {
                    Button(action: onAddToCalendar) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
                
                // Dismiss button
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

//#Preview { /* Preview removed to avoid referencing old types */ // }

