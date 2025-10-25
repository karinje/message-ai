//
//  MessageStatus.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation

enum MessageStatus: String, Codable {
    case pending = "pending"     // Waiting for network (offline)
    case sending = "sending"     // Actively sending to server
    case sent = "sent"           // Server confirmed receipt
    case delivered = "delivered" // Delivered to recipient's device
    case read = "read"           // Read by recipient
    case failed = "failed"       // Send failed, needs retry
}

