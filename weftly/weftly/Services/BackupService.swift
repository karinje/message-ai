//
//  BackupService.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import Foundation
import FirebaseStorage
import SwiftData

@MainActor
class BackupService {
    static let shared = BackupService()
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Backup
    
    func performBackup(userId: String, modelContext: ModelContext) async throws {
        print("[BackupService] Starting backup for user: \(userId)")
        
        // Get the SwiftData container's file URL
        guard let backupURL = try? getBackupFileURL() else {
            throw BackupError.failedToAccessDatabase
        }
        
        print("[BackupService] Backup file path: \(backupURL.path)")
        
        // Read the database file
        guard let backupData = try? Data(contentsOf: backupURL) else {
            throw BackupError.failedToReadDatabase
        }
        
        print("[BackupService] Database file size: \(backupData.count) bytes")
        
        // Upload to Firebase Storage
        let storagePath = "users/\(userId)/backups/backup_latest.db"
        let storageRef = storage.reference().child(storagePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "application/octet-stream"
        metadata.customMetadata = [
            "backupDate": ISO8601DateFormatter().string(from: Date()),
            "userId": userId
        ]
        
        print("[BackupService] Uploading to Firebase Storage: \(storagePath)")
        
        _ = try await storageRef.putDataAsync(backupData, metadata: metadata)
        
        print("[BackupService] Backup completed successfully")
    }
    
    // MARK: - Restore
    
    func performRestore(userId: String) async throws {
        print("[BackupService] Starting restore for user: \(userId)")
        
        let storagePath = "users/\(userId)/backups/backup_latest.db"
        let storageRef = storage.reference().child(storagePath)
        
        // Check if backup exists
        do {
            _ = try await storageRef.getMetadata()
        } catch {
            throw BackupError.noBackupFound
        }
        
        // Download backup file
        print("[BackupService] Downloading backup from Firebase Storage")
        let maxSize: Int64 = 100 * 1024 * 1024 // 100 MB
        let backupData = try await storageRef.data(maxSize: maxSize)
        
        print("[BackupService] Downloaded backup size: \(backupData.count) bytes")
        
        // Get the SwiftData container's file URL
        guard let restoreURL = try? getBackupFileURL() else {
            throw BackupError.failedToAccessDatabase
        }
        
        // Write the backup data to replace existing database
        try backupData.write(to: restoreURL, options: .atomic)
        
        print("[BackupService] Restore completed successfully. App needs restart.")
    }
    
    func checkBackupExists(userId: String) async -> Bool {
        let storagePath = "users/\(userId)/backups/backup_latest.db"
        let storageRef = storage.reference().child(storagePath)
        
        do {
            _ = try await storageRef.getMetadata()
            return true
        } catch {
            return false
        }
    }
    
    func getBackupMetadata(userId: String) async throws -> BackupMetadata {
        let storagePath = "users/\(userId)/backups/backup_latest.db"
        let storageRef = storage.reference().child(storagePath)
        
        let metadata = try await storageRef.getMetadata()
        
        let dateString = metadata.customMetadata?["backupDate"] ?? ""
        let backupDate = ISO8601DateFormatter().date(from: dateString)
        
        return BackupMetadata(
            date: backupDate ?? Date(),
            size: metadata.size
        )
    }
    
    // MARK: - Helper Methods
    
    private func getBackupFileURL() throws -> URL {
        // SwiftData stores its database in the app's Application Support directory
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw BackupError.failedToAccessDatabase
        }
        
        // The default SwiftData database file is typically named "default.store"
        // You may need to adjust this based on your SwiftData configuration
        let databaseURL = appSupportURL.appendingPathComponent("default.store")
        
        return databaseURL
    }
}

// MARK: - Error Types

enum BackupError: LocalizedError {
    case failedToAccessDatabase
    case failedToReadDatabase
    case failedToWriteDatabase
    case noBackupFound
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .failedToAccessDatabase:
            return "Failed to access local database"
        case .failedToReadDatabase:
            return "Failed to read database file"
        case .failedToWriteDatabase:
            return "Failed to write database file"
        case .noBackupFound:
            return "No backup found in cloud storage"
        case .uploadFailed:
            return "Failed to upload backup to cloud"
        case .downloadFailed:
            return "Failed to download backup from cloud"
        }
    }
}

// MARK: - Metadata

struct BackupMetadata {
    let date: Date
    let size: Int64
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

