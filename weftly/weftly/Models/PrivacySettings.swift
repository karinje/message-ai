//
//  PrivacySettings.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import Foundation

struct PrivacySettings: Codable, Equatable {
    var lastSeenEnabled: Bool
    var readReceiptsEnabled: Bool
    
    // DEFAULT: Privacy protection DISABLED = sharing enabled (social by default)
    // lastSeenEnabled: true = You share your status (privacy OFF)
    // readReceiptsEnabled: true = You send blue ticks (privacy OFF)
    init(lastSeenEnabled: Bool = true, readReceiptsEnabled: Bool = true) {
        self.lastSeenEnabled = lastSeenEnabled
        self.readReceiptsEnabled = readReceiptsEnabled
    }
    
    enum CodingKeys: String, CodingKey {
        case lastSeenEnabled
        case readReceiptsEnabled
    }
}

