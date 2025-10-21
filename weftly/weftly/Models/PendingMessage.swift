//
//  PendingMessage.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import SwiftData

@Model
final class PendingMessage {
    @Attribute(.unique) var id: String
    var conversationId: String
    var text: String
    var imageData: Data?
    var timestamp: Date
    var retryCount: Int
    
    init(id: String = UUID().uuidString, conversationId: String, text: String, imageData: Data? = nil, timestamp: Date = Date(), retryCount: Int = 0) {
        self.id = id
        self.conversationId = conversationId
        self.text = text
        self.imageData = imageData
        self.timestamp = timestamp
        self.retryCount = retryCount
    }
}

