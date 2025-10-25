//
//  CloudBackupViewModel.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import Foundation
import SwiftData
import FirebaseFirestore
import Combine

@MainActor
class CloudBackupViewModel: ObservableObject {
    @Published var backupEnabled: Bool = false
    @Published var backupSchedule: BackupSchedule = .weekly
    @Published var lastBackupAt: Date?
    @Published var isBackingUp: Bool = false
    @Published var isRestoring: Bool = false
    @Published var backupExists: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let authService: AuthService
    private let db = Firestore.firestore()
    private var modelContext: ModelContext?
    
    init(authService: AuthService) {
        self.authService = authService
        Task {
            await loadSettings()
            await checkBackupExists()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Load Settings
    
    func loadSettings() async {
        guard let userId = authService.currentUser?.id else { return }
        
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            if let user = try? doc.data(as: User.self) {
                self.backupEnabled = user.cloudBackupSettings.backupEnabled
                self.backupSchedule = user.cloudBackupSettings.backupSchedule
                self.lastBackupAt = user.cloudBackupSettings.lastBackupAt
            }
        } catch {
            print("[CloudBackupViewModel] Error loading settings: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Toggle Backup
    
    func toggleBackup(_ enabled: Bool) async {
        guard let userId = authService.currentUser?.id else { return }
        
        self.backupEnabled = enabled
        
        do {
            try await db.collection("users").document(userId).updateData([
                "cloudBackupSettings.backupEnabled": enabled
            ])
            
            // If enabling backup, perform initial backup
            if enabled {
                await performBackupNow()
            }
        } catch {
            print("[CloudBackupViewModel] Error toggling backup: \(error.localizedDescription)")
            errorMessage = "Failed to update backup settings"
        }
    }
    
    // MARK: - Update Schedule
    
    func updateSchedule(_ schedule: BackupSchedule) async {
        guard let userId = authService.currentUser?.id else { return }
        
        self.backupSchedule = schedule
        
        do {
            try await db.collection("users").document(userId).updateData([
                "cloudBackupSettings.backupSchedule": schedule.rawValue
            ])
        } catch {
            print("[CloudBackupViewModel] Error updating schedule: \(error.localizedDescription)")
            errorMessage = "Failed to update backup schedule"
        }
    }
    
    // MARK: - Perform Backup
    
    func performBackupNow() async {
        guard let userId = authService.currentUser?.id,
              let context = modelContext else {
            errorMessage = "Backup failed: No user or context"
            return
        }
        
        isBackingUp = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await BackupService.shared.performBackup(userId: userId, modelContext: context)
            
            let now = Date()
            self.lastBackupAt = now
            
            // Update lastBackupAt in Firestore
            try await db.collection("users").document(userId).updateData([
                "cloudBackupSettings.lastBackupAt": now
            ])
            
            successMessage = "Backup completed successfully"
            await checkBackupExists()
        } catch {
            print("[CloudBackupViewModel] Backup failed: \(error.localizedDescription)")
            errorMessage = "Backup failed: \(error.localizedDescription)"
        }
        
        isBackingUp = false
    }
    
    // MARK: - Restore Backup
    
    func restoreFromBackup() async {
        guard let userId = authService.currentUser?.id else {
            errorMessage = "Restore failed: No user"
            return
        }
        
        isRestoring = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await BackupService.shared.performRestore(userId: userId)
            successMessage = "Restore completed. Please restart the app."
        } catch {
            print("[CloudBackupViewModel] Restore failed: \(error.localizedDescription)")
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
        
        isRestoring = false
    }
    
    // MARK: - Check Backup Exists
    
    func checkBackupExists() async {
        guard let userId = authService.currentUser?.id else { return }
        
        backupExists = await BackupService.shared.checkBackupExists(userId: userId)
    }
    
    // MARK: - Should Auto Backup
    
    func shouldAutoBackup() -> Bool {
        guard backupEnabled else { return false }
        
        guard let lastBackup = lastBackupAt else {
            return true // Never backed up, do it now
        }
        
        let timeSinceLastBackup = Date().timeIntervalSince(lastBackup)
        return timeSinceLastBackup >= backupSchedule.intervalInSeconds
    }
}

