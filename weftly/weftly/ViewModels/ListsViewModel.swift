//
//  ListsViewModel.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class ListsViewModel: ObservableObject {
    @Published var customLists: [ConversationList] = []
    @Published var presetLists: [ConversationList] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    let authService: AuthService  // Public for UserSelectionView access
    
    init(authService: AuthService) {
        self.authService = authService
        setupPresetLists()
    }
    
    private func setupPresetLists() {
        presetLists = [
            .unreadList,
            .favoritesList,
            .groupsList
        ]
    }
    
    func startListening() {
        guard let userId = authService.currentUser?.id else { return }
        
        listener = db.collection("users").document(userId).collection("lists")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let lists = documents.compactMap { doc -> ConversationList? in
                    try? doc.data(as: ConversationList.self)
                }
                
                // Filter custom vs preset lists
                self.customLists = lists.filter { !$0.isPreset }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func createList(name: String, userIds: [String], icon: String? = nil) async throws {
        guard let userId = authService.currentUser?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let listId = UUID().uuidString
        var list = ConversationList(
            name: name,
            conversationIds: [],  // Keep empty for backward compatibility
            userIds: userIds,
            icon: icon,
            isPreset: false
        )
        list.id = listId
        
        try db.collection("users").document(userId).collection("lists").document(listId)
            .setData(from: list)
    }
    
    func addConversationToList(listId: String, conversationId: String) async throws {
        guard let userId = authService.currentUser?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        try await db.collection("users").document(userId).collection("lists").document(listId)
            .updateData([
                "conversationIds": FieldValue.arrayUnion([conversationId]),
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    func removeConversationFromList(listId: String, conversationId: String) async throws {
        guard let userId = authService.currentUser?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        try await db.collection("users").document(userId).collection("lists").document(listId)
            .updateData([
                "conversationIds": FieldValue.arrayRemove([conversationId]),
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    func deleteList(listId: String) async throws {
        guard let userId = authService.currentUser?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        try await db.collection("users").document(userId).collection("lists").document(listId).delete()
    }
    
    // Filter conversations based on selected list
    func filterConversations(_ conversations: [Conversation], for list: ConversationList, currentUserId: String) -> [Conversation] {
        switch list.id {
        case "preset-unread":
            // Use timestamp-based unread detection
            return conversations.filter { conv in
                conv.lastMessageSenderId != currentUserId &&
                (conv.lastMessageTime ?? .distantPast) > (conv.lastReadTime[currentUserId] ?? .distantPast)
            }
        case "preset-favorites":
            // For now, return conversations that are in the favorites list
            return conversations.filter { conv in
                guard let convId = conv.id else { return false }
                return list.conversationIds.contains(convId)
            }
        case "preset-groups":
            return conversations.filter { conv in
                conv.type == .group
            }
        default:
            // Custom list - filter by userIds (NEW LOGIC)
            // Show conversations where any participant is in the list's userIds
            if !list.userIds.isEmpty {
                return conversations.filter { conv in
                    // For each conversation, check if any participant is in the list's userIds
                    // Exclude current user from check (we want to filter by OTHER users)
                    let otherParticipants = conv.participants.filter { $0 != currentUserId }
                    return otherParticipants.contains(where: { list.userIds.contains($0) })
                }
            } else {
                // Fallback to old conversationIds logic for backward compatibility
                return conversations.filter { conv in
                    guard let convId = conv.id else { return false }
                    return list.conversationIds.contains(convId)
                }
            }
        }
    }
}

