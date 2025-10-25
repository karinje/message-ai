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
    var privacySettings: PrivacySettings
    var about: String?
    var phoneNumber: String?
    var cloudBackupSettings: CloudBackupSettings
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case profilePictureUrl
        case isOnline
        case lastSeen
        case fcmToken
        case privacySettings
        case about
        case phoneNumber
        case cloudBackupSettings
    }
    
    init(id: String? = nil, email: String, displayName: String, profilePictureUrl: String? = nil, isOnline: Bool = false, lastSeen: Date = Date(), fcmToken: String? = nil, privacySettings: PrivacySettings = PrivacySettings(), about: String? = nil, phoneNumber: String? = nil, cloudBackupSettings: CloudBackupSettings = CloudBackupSettings()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profilePictureUrl = profilePictureUrl
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.fcmToken = fcmToken
        self.privacySettings = privacySettings
        self.about = about
        self.phoneNumber = phoneNumber
        self.cloudBackupSettings = cloudBackupSettings
    }
    
    // Custom decoder to handle missing privacySettings in old documents
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)
        profilePictureUrl = try container.decodeIfPresent(String.self, forKey: .profilePictureUrl)
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        lastSeen = try container.decode(Date.self, forKey: .lastSeen)
        fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
        // Provide default if missing
        privacySettings = (try? container.decode(PrivacySettings.self, forKey: .privacySettings)) ?? PrivacySettings()
        about = try container.decodeIfPresent(String.self, forKey: .about)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        cloudBackupSettings = (try? container.decode(CloudBackupSettings.self, forKey: .cloudBackupSettings)) ?? CloudBackupSettings()
    }
}

