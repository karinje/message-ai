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
    
    private let userId: String?
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init(userId: String?) {
        self.userId = userId
        
        if let userId = userId {
            startListening(userId: userId)
        }
    }
    
    deinit {
        listener?.remove()
    }
    
    private func startListening(userId: String) {
        listener = db.collection("users")
            .document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to user presence: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let isOnlineBool = data["isOnline"] as? Bool,
                      let lastSeenTimestamp = data["lastSeen"] as? Timestamp else {
                    print("⚠️ Missing presence data for user \(userId)")
                    Task { @MainActor in
                        self.isOnline = false
                    }
                    return
                }
                
                let lastSeen = lastSeenTimestamp.dateValue()
                let timeSinceLastSeen = Date().timeIntervalSince(lastSeen)
                
                // User is online if:
                // 1. isOnline flag is true
                // 2. OR last seen was within 5 minutes (300 seconds)
                let calculatedOnline = isOnlineBool || timeSinceLastSeen < 300
                
                print("👤 User \(userId): isOnline=\(isOnlineBool), lastSeen=\(Int(timeSinceLastSeen))s ago, computed=\(calculatedOnline)")
                
                Task { @MainActor in
                    self.isOnline = calculatedOnline
                }
            }
    }
}

