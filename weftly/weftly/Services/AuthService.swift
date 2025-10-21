//
//  AuthService.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        // Check if user is already logged in
        if let firebaseUser = auth.currentUser {
            Task {
                await fetchCurrentUser(userId: firebaseUser.uid)
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws -> User {
        let authResult = try await auth.createUser(withEmail: email, password: password)
        
        // Create user document in Firestore
        let user = User(
            id: authResult.user.uid,
            email: email,
            displayName: displayName,
            isOnline: true,
            lastSeen: Date()
        )
        
        try await db.collection("users").document(authResult.user.uid).setData([
            "email": user.email,
            "displayName": user.displayName,
            "isOnline": user.isOnline,
            "lastSeen": Timestamp(date: user.lastSeen)
        ])
        
        self.currentUser = user
        self.isAuthenticated = true
        
        return user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let authResult = try await auth.signIn(withEmail: email, password: password)
        
        // Update online status
        try await db.collection("users").document(authResult.user.uid).updateData([
            "isOnline": true,
            "lastSeen": Timestamp(date: Date())
        ])
        
        await fetchCurrentUser(userId: authResult.user.uid)
        
        guard let user = currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user data"])
        }
        
        return user
    }
    
    func signOut() throws {
        guard let userId = auth.currentUser?.uid else { return }
        
        // Update offline status
        Task {
            try? await db.collection("users").document(userId).updateData([
                "isOnline": false,
                "lastSeen": Timestamp(date: Date())
            ])
        }
        
        try auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    func fetchCurrentUser(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let user = try? document.data(as: User.self) {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
        }
    }
    
    func updateProfile(displayName: String? = nil, profilePictureUrl: String? = nil) async throws {
        guard let userId = currentUser?.id else { return }
        
        var updates: [String: Any] = [:]
        if let displayName = displayName {
            updates["displayName"] = displayName
        }
        if let profilePictureUrl = profilePictureUrl {
            updates["profilePictureUrl"] = profilePictureUrl
        }
        
        try await db.collection("users").document(userId).updateData(updates)
        await fetchCurrentUser(userId: userId)
    }
    
    func updateFCMToken(_ token: String) async {
        guard let userId = currentUser?.id else { return }
        
        try? await db.collection("users").document(userId).updateData([
            "fcmToken": token
        ])
    }
}

