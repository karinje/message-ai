//
//  PresenceViewModel.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class PresenceViewModel: ObservableObject {
    @Published var isOnline: Bool = false
    @Published var lastSeen: Date?
    
    private let userId: String?
    private let currentUserId: String?
    private let db = Firestore.firestore()
    private var targetUserListener: ListenerRegistration?
    private var privacyCancellable: AnyCancellable?
    
    // Cache the latest presence data to avoid redundant checks
    private var latestIsOnline: Bool = false
    private var latestLastSeen: Date?
    
    init(userId: String?, currentUserId: String? = nil) {
        self.userId = userId
        self.currentUserId = currentUserId
        
        if let userId = userId {
            print("🎯 PresenceViewModel init for user: \(userId)")
            startListening(userId: userId)
            
            // Start listening to this user's privacy settings via PrivacyManager
            PrivacyManager.shared.startListeningToUser(userId: userId)
            
            // Listen to PrivacyManager's privacy changes (both users)
            if currentUserId != nil {
                subscribeToPrivacyChanges()
            }
        } else {
            print("⚠️ PresenceViewModel init with nil userId")
        }
    }
    
    deinit {
        targetUserListener?.remove()
        privacyCancellable?.cancel()
        
        // Stop listening to this user's privacy when view is destroyed
        if let userId = userId {
            PrivacyManager.shared.stopListeningToUser(userId: userId)
        }
    }
    
    private func startListening(userId: String) {
        print("🔊 Starting presence listener for user: \(userId)")
        
        targetUserListener = db.collection("users")
            .document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to user presence for \(userId): \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    print("⚠️ User document doesn't exist for \(userId)")
                    Task { @MainActor in
                        self.isOnline = false
                    }
                    return
                }
                
                guard let data = snapshot.data(),
                      let isOnlineBool = data["isOnline"] as? Bool,
                      let lastSeenTimestamp = data["lastSeen"] as? Timestamp else {
                    print("⚠️ Missing presence fields for user \(userId). Data: \(snapshot.data() ?? [:])")
                    Task { @MainActor in
                        self.isOnline = false
                    }
                    return
                }
                
                let lastSeen = lastSeenTimestamp.dateValue()
                let timeSinceLastSeen = Date().timeIntervalSince(lastSeen)
                
                // Hybrid presence logic:
                // 1. If lastSeen > 10 minutes: OFFLINE (handles stuck isOnline=true from crashes)
                // 2. If isOnline=false: OFFLINE (handles explicit signout, regardless of lastSeen)
                // 3. If isOnline=true AND lastSeen < 10 min: ONLINE (active user)
                //
                // No heartbeat = cheaper Firestore writes
                // Only updates on: open chat, send message, app foreground
                // 10-min timeout allows silent reading without showing offline
                let calculatedOnline: Bool
                if timeSinceLastSeen > 600 {
                    // Been inactive for > 10 minutes - definitely offline
                    calculatedOnline = false
                } else if !isOnlineBool {
                    // Explicitly signed out/backgrounded (even if recent) - show offline immediately
                    calculatedOnline = false
                } else {
                    // Online flag is true and recently active - show online
                    calculatedOnline = true
                }
                
                print("👤 User \(userId): isOnline=\(isOnlineBool), lastSeen=\(Int(timeSinceLastSeen))s ago, computed=\(calculatedOnline)")
                
                // Cache the latest presence data and apply privacy check
                Task { @MainActor in
                    self.latestIsOnline = calculatedOnline
                    self.latestLastSeen = lastSeen
                    
                    // Apply privacy check and update UI (synchronous now!)
                    self.updatePresenceWithPrivacyCheck(targetUserId: userId)
                }
            }
    }
    
    /// Subscribe to shared PrivacyManager's privacy changes (both current user and target user)
    private func subscribeToPrivacyChanges() {
        // Listen to any privacy changes (either user)
        privacyCancellable = PrivacyManager.shared.$userPrivacySettings
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if let targetUserId = self.userId {
                    self.updatePresenceWithPrivacyCheck(targetUserId: targetUserId)
                }
            }
    }
    
    /// Update presence display based on latest presence data and current privacy settings
    private func updatePresenceWithPrivacyCheck(targetUserId: String) {
        guard let currentUserId = currentUserId else {
            // No privacy check possible - show presence
            self.isOnline = latestIsOnline
            self.lastSeen = latestLastSeen
            return
        }
        
        // Use shared PrivacyManager (real-time, no async needed!)
        let shouldShowPresence = PrivacyManager.shared.shouldShowPresence(
            targetUserId: targetUserId,
            currentUserId: currentUserId
        )
        
        if shouldShowPresence {
            self.isOnline = latestIsOnline
            self.lastSeen = latestLastSeen
        } else {
            // Privacy disabled - always show offline
            self.isOnline = false
            self.lastSeen = nil
        }
    }
}

