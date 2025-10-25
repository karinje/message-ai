import SwiftUI

struct CalendarEventsSection: View {
    let events: [ExtractedEvent]
    @ObservedObject var viewModel: DigestViewModel
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                    
                    Text("Upcoming Events")
                        .font(.headline)
                    
                    Spacer()
                    
                    if upcomingEvents.count > 0 {
                        Text("\(upcomingEvents.count)")
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
                // Group events by time
                if !todayEvents.isEmpty {
                    SectionGroup(title: "Today", events: todayEvents, viewModel: viewModel)
                }
                
                if !thisWeekEvents.isEmpty {
                    SectionGroup(title: "This Week", events: thisWeekEvents, viewModel: viewModel)
                }
                
                if !laterEvents.isEmpty {
                    SectionGroup(title: "Later", events: laterEvents, viewModel: viewModel)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    // MARK: - Grouped Events
    var upcomingEvents: [ExtractedEvent] {
        events.filter { $0.date > Date() }.sorted { $0.date < $1.date }
    }
    
    var todayEvents: [ExtractedEvent] {
        upcomingEvents.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    var thisWeekEvents: [ExtractedEvent] {
        let calendar = Calendar.current
        let today = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        
        return upcomingEvents.filter {
            !calendar.isDateInToday($0.date) && $0.date < weekFromNow
        }
    }
    
    var laterEvents: [ExtractedEvent] {
        let calendar = Calendar.current
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        return upcomingEvents.filter { $0.date >= weekFromNow }
    }
}

struct SectionGroup: View {
    let title: String
    let events: [ExtractedEvent]
    @ObservedObject var viewModel: DigestViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            
            ForEach(events) { event in
                EventCardView(event: event, onAddToCalendar: {
                    Task {
                        await viewModel.addEventToCalendar(event)
                    }
                })
            }
        }
    }
}

#Preview {
    CalendarEventsSection(
        events: [
            ExtractedEvent(
                title: "Soccer practice",
                date: Date().addingTimeInterval(3600),
                location: "Park",
                confidence: 0.95,
                messageId: "123",
                conversationId: "456"
            )
        ],
        viewModel: DigestViewModel(authService: AuthService())
    )
    .padding()
}

