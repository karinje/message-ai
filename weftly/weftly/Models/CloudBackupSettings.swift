//
//  CloudBackupSettings.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import Foundation

struct CloudBackupSettings: Codable, Equatable {
    var backupEnabled: Bool
    var backupSchedule: BackupSchedule
    var lastBackupAt: Date?
    
    init(backupEnabled: Bool = false, backupSchedule: BackupSchedule = .weekly, lastBackupAt: Date? = nil) {
        self.backupEnabled = backupEnabled
        self.backupSchedule = backupSchedule
        self.lastBackupAt = lastBackupAt
    }
    
    enum CodingKeys: String, CodingKey {
        case backupEnabled
        case backupSchedule
        case lastBackupAt
    }
}

enum BackupSchedule: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
    
    var intervalInSeconds: TimeInterval {
        switch self {
        case .daily: return 24 * 60 * 60
        case .weekly: return 7 * 24 * 60 * 60
        case .monthly: return 30 * 24 * 60 * 60
        }
    }
}

