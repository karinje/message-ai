//
//  MessageStatus.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation

enum MessageStatus: String, Codable {
    case sending = "sending"     // Optimistic UI, not yet confirmed by server
    case sent = "sent"           // Server confirmed receipt
    case delivered = "delivered" // Delivered to recipient's device
    case read = "read"           // Read by recipient
    case failed = "failed"       // Send failed, needs retry
}

