//
//  AuthService.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import Combine
import FirebaseMessaging
import SwiftData

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isCheckingAuth = true // NEW: Track initial auth check
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Observe Firebase auth state
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            Task { @MainActor in
                if let user {
                    await self.fetchCurrentUser(userId: user.uid)
                    self.isAuthenticated = true
                    self.isCheckingAuth = false
                    self.refreshFCMToken()
                } else {
                    NotificationService.shared.clearFCMToken()
                    self.currentUser = nil
                    self.isAuthenticated = false
                    self.isCheckingAuth = false
                }
            }
        }
        
        // Initial fetch if already logged in
        if let firebaseUser = auth.currentUser {
            Task {
                await fetchCurrentUser(userId: firebaseUser.uid)
                self.isAuthenticated = true
                self.isCheckingAuth = false
                self.refreshFCMToken()
            }
        } else {
            // No user, done checking
            self.isCheckingAuth = false
        }
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    func signInWithGoogle() async throws -> User {
        guard let clientID = auth.app?.options.clientID else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No client ID found"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = result.user
        
        guard let idToken = user.idToken?.tokenString else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ID token"])
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
        let authResult = try await auth.signIn(with: credential)
        
        // Check if user exists in Firestore
        let userDoc = try await db.collection("users").document(authResult.user.uid).getDocument()
        
        if !userDoc.exists {
            // Create new user
            let newUser = User(
                id: authResult.user.uid,
                email: authResult.user.email ?? "",
                displayName: authResult.user.displayName ?? "User",
                profilePictureUrl: authResult.user.photoURL?.absoluteString,
                isOnline: true,
                lastSeen: Date()
            )
            
            try await db.collection("users").document(authResult.user.uid).setData([
                "email": newUser.email,
                "displayName": newUser.displayName,
                "profilePictureUrl": newUser.profilePictureUrl ?? "",
                "isOnline": newUser.isOnline,
                "lastSeen": Timestamp(date: newUser.lastSeen),
                "privacySettings": [
                    "lastSeenEnabled": true,  // Social by default: sharing enabled
                    "readReceiptsEnabled": true
                ]
            ])
            
            self.currentUser = newUser
            self.isAuthenticated = true
            self.refreshFCMToken()
            return newUser
        } else {
            // Update online status
            try await db.collection("users").document(authResult.user.uid).updateData([
                "isOnline": true,
                "lastSeen": Timestamp(date: Date())
            ])
            
            await fetchCurrentUser(userId: authResult.user.uid)
            self.refreshFCMToken()
            
            guard let currentUser = currentUser else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user data"])
            }
            
            return currentUser
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
            "lastSeen": Timestamp(date: user.lastSeen),
            "privacySettings": [
                "lastSeenEnabled": true,  // Social by default: sharing enabled
                "readReceiptsEnabled": true
            ]
        ])
        
        self.currentUser = user
        self.isAuthenticated = true
        self.refreshFCMToken()
        
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
        self.refreshFCMToken()
        
        guard let user = currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user data"])
        }
        
        return user
    }
    
    func signOut() async throws {
        guard let userId = auth.currentUser?.uid else { return }
        
        print("👋 Signing out user \(userId), setting offline...")
        
        // Update offline status BEFORE signing out
        do {
            try await db.collection("users").document(userId).updateData([
                "isOnline": false,
                "lastSeen": Timestamp(date: Date())
            ])
            print("✅ Presence set to offline")
        } catch {
            print("⚠️ Failed to update offline status: \(error.localizedDescription)")
        }
        
        try auth.signOut()
        NotificationService.shared.clearFCMToken()
        self.currentUser = nil
        self.isAuthenticated = false
        
        print("✅ Sign out complete")
    }
    
    func fetchCurrentUser(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if var user = try? document.data(as: User.self) {
                if user.id == nil { user.id = document.documentID }
                self.currentUser = user
                self.isAuthenticated = true
                self.refreshFCMToken()
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
    
    func updateProfilePicture(url: String) async throws {
        guard let userId = currentUser?.id else { return }
        
        // Update user document (just marks that user HAS a profile picture)
        try await db.collection("users").document(userId).updateData([
            "profilePictureUrl": url
        ])
        
        // NOTE: No need to update conversations!
        // URL is always the same (overwrites same file in Storage)
        // Everyone automatically sees new photo via cache invalidation
        
        await fetchCurrentUser(userId: userId)
    }
    
    func updateAbout(_ about: String) async throws {
        guard let userId = currentUser?.id else { return }
        
        try await db.collection("users").document(userId).updateData([
            "about": about
        ])
        await fetchCurrentUser(userId: userId)
    }
    
    func deleteAllChats(modelContext: ModelContext) async throws {
        // Delete local SwiftData messages
        let messageDescriptor = FetchDescriptor<LocalMessage>()
        let allMessages = try modelContext.fetch(messageDescriptor)
        
        print("🗑️ Deleting \(allMessages.count) local messages")
        
        for message in allMessages {
            modelContext.delete(message)
        }
        
        // Delete local conversation states (unread counters)
        let stateDescriptor = FetchDescriptor<LocalConversationState>()
        let allStates = try modelContext.fetch(stateDescriptor)
        
        print("🗑️ Deleting \(allStates.count) conversation states")
        
        for state in allStates {
            modelContext.delete(state)
        }
        
        // Delete pending messages
        let pendingDescriptor = FetchDescriptor<PendingMessage>()
        let pendingMessages = try modelContext.fetch(pendingDescriptor)
        
        print("🗑️ Deleting \(pendingMessages.count) pending messages")
        
        for pending in pendingMessages {
            modelContext.delete(pending)
        }
        
        try modelContext.save()
        print("✅ All local chats deleted")
    }
    
    func deleteAccount() async throws {
        guard let userId = auth.currentUser?.uid else { return }
        
        // Delete user document from Firestore
        try await db.collection("users").document(userId).delete()
        
        // Delete Firebase Auth account
        try await auth.currentUser?.delete()
        
        NotificationService.shared.clearFCMToken()
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    func updateFCMToken(_ token: String) async {
        guard let userId = currentUser?.id else { return }
        
        try? await db.collection("users").document(userId).updateData([
            "fcmToken": token
        ])
    }
    
    func updatePresence(isOnline: Bool) async {
        guard let userId = currentUser?.id else { return }
        
        print("👤 Updating presence for user \(userId): isOnline=\(isOnline)")
        
        do {
            try await db.collection("users").document(userId).updateData([
                "isOnline": isOnline,
                "lastSeen": Timestamp(date: Date())
            ])
            
            // Update local user object
            if var user = currentUser {
                user.isOnline = isOnline
                user.lastSeen = Date()
                self.currentUser = user
            }
        } catch {
            print("❌ Error updating presence: \(error.localizedDescription)")
        }
    }

    private func refreshFCMToken() {
        Messaging.messaging().token { token, error in
            if let error {
                print("Failed to fetch FCM token: \(error.localizedDescription)")
                return
            }
            guard let token else { return }
            Task { await NotificationService.shared.updateFCMToken(token) }
        }
    }
}

