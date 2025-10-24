//
//  ChatHeaderView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI

struct ChatHeaderView: View {
    let displayName: String
    let otherUserId: String?
    @StateObject private var presenceViewModel: PresenceViewModel
    
    init(displayName: String, otherUserId: String?) {
        self.displayName = displayName
        self.otherUserId = otherUserId
        _presenceViewModel = StateObject(wrappedValue: PresenceViewModel(userId: otherUserId))
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(displayName)
                .font(.headline)
            
            if presenceViewModel.isOnline {
                Text("online")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let lastSeen = presenceViewModel.lastSeen {
                Text(lastSeenText(from: lastSeen))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func lastSeenText(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if let day = components.day {
            if day == 0 {
                // Today
                return "last seen today at \(formatter.string(from: date))"
            } else if day == 1 {
                // Yesterday
                return "last seen yesterday at \(formatter.string(from: date))"
            } else if day < 7 {
                // Within a week
                formatter.dateFormat = "EEEE" // Day name
                return "last seen \(formatter.string(from: date)) at \(formatter.string(from: date))"
            } else {
                // Older
                formatter.dateFormat = "M/d/yy"
                let dateStr = formatter.string(from: date)
                formatter.timeStyle = .short
                return "last seen \(dateStr) at \(formatter.string(from: date))"
            }
        }
        
        return "last seen recently"
    }
}

