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
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init(userId: String?) {
        self.userId = userId
        
        if let userId = userId {
            print("🎯 PresenceViewModel init for user: \(userId)")
            startListening(userId: userId)
        } else {
            print("⚠️ PresenceViewModel init with nil userId")
        }
    }
    
    deinit {
        listener?.remove()
    }
    
    private func startListening(userId: String) {
        print("🔊 Starting presence listener for user: \(userId)")
        
        listener = db.collection("users")
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
                
                Task { @MainActor in
                    self.isOnline = calculatedOnline
                    self.lastSeen = lastSeen
                }
            }
    }
}

