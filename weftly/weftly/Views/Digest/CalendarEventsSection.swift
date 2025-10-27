import SwiftUI

struct CalendarEventsSection: View {
    let events: [DigestEvent]
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
    var upcomingEvents: [DigestEvent] {
        let now = Date()
        let filtered = events.filter { $0.date > now }.sorted { $0.date < $1.date }
        return filtered
    }
    
    var todayEvents: [DigestEvent] {
        upcomingEvents.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    var thisWeekEvents: [DigestEvent] {
        let calendar = Calendar.current
        let today = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        
        return upcomingEvents.filter {
            !calendar.isDateInToday($0.date) && $0.date < weekFromNow
        }
    }
    
    var laterEvents: [DigestEvent] {
        let calendar = Calendar.current
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        return upcomingEvents.filter { $0.date >= weekFromNow }
    }
}

struct SectionGroup: View {
    let title: String
    let events: [DigestEvent]
    @ObservedObject var viewModel: DigestViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            
            ForEach(events) { event in
                EventCardView(
                    event: event,
                    onAddToCalendar: {
                        Task {
                            await viewModel.addEventToCalendar(event)
                        }
                    },
                    onDismiss: {
                        Task {
                            await viewModel.dismissEvent(event)
                        }
                    }
                )
            }
        }
    }
}

//#Preview { /* Preview removed to avoid referencing old types */ // }

