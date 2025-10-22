//
//  User.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Equatable {
    var id: String?
    var email: String
    var displayName: String
    var profilePictureUrl: String?
    var isOnline: Bool
    var lastSeen: Date
    var fcmToken: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case profilePictureUrl
        case isOnline
        case lastSeen
        case fcmToken
    }
    
    init(id: String? = nil, email: String, displayName: String, profilePictureUrl: String? = nil, isOnline: Bool = false, lastSeen: Date = Date(), fcmToken: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profilePictureUrl = profilePictureUrl
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.fcmToken = fcmToken
    }
}

