//
//  DateFormatter+Extensions.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let day = components.day, day >= 2 {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        } else if let day = components.day, day >= 1 {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Yesterday \(formatter.string(from: self))"
        } else if let hour = components.hour, hour >= 1 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute >= 1 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}

