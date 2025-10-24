//
//  PrivacyViewModel.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class PrivacyViewModel: ObservableObject {
    @Published var lastSeenEnabled: Bool = true {
        didSet {
            if lastSeenEnabled != oldValue {
                Task { await saveSettings() }
            }
        }
    }
    
    @Published var readReceiptsEnabled: Bool = true {
        didSet {
            if readReceiptsEnabled != oldValue {
                Task { await saveSettings() }
            }
        }
    }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
        Task {
            await loadSettings()
        }
    }
    
    func loadSettings() async {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            if let user = try? doc.data(as: User.self) {
                self.lastSeenEnabled = user.privacySettings.lastSeenEnabled
                self.readReceiptsEnabled = user.privacySettings.readReceiptsEnabled
            }
        } catch {
            self.errorMessage = "Error loading privacy settings: \(error.localizedDescription)"
        }
    }
    
    private func saveSettings() async {
        guard let userId = authService.currentUser?.id else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "privacySettings.lastSeenEnabled": lastSeenEnabled,
                "privacySettings.readReceiptsEnabled": readReceiptsEnabled
            ])
        } catch {
            self.errorMessage = "Error saving privacy settings: \(error.localizedDescription)"
        }
    }
}

