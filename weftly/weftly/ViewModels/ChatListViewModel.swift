//
//  ChatListViewModel.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import SwiftUI

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    
    private let firestoreService = FirestoreService()
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func startListening() {
        guard let userId = authService.currentUser?.id else { return }
        
        firestoreService.listenToConversations(userId: userId) { [weak self] conversations in
            self?.conversations = conversations
        }
    }
    
    func stopListening() {
        firestoreService.removeConversationListener()
    }
    
    func createDirectConversation(with user: User) async throws -> Conversation {
        guard let currentUser = authService.currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        return try await firestoreService.createDirectConversation(with: user, currentUser: currentUser)
    }
    
    func createGroupConversation(name: String, participants: [User]) async throws -> Conversation {
        guard let currentUser = authService.currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        return try await firestoreService.createGroupConversation(name: name, participants: participants, currentUser: currentUser)
    }
}

