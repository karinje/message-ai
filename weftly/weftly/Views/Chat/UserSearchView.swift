//
//  UserSearchView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI

struct UserSearchView: View {
    @Environment(\.dismiss) var dismiss
    let authService: AuthService
    let viewModel: ChatListViewModel
    
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    
    private let firestoreService = FirestoreService()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(searchResults) { user in
                    Button {
                        startChat(with: user)
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(user.displayName.prefix(2).uppercased())
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                )
                            
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if user.isOnline {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search by name")
            .onChange(of: searchText) { _, newValue in
                searchUsers(query: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchUsers(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task { @MainActor in
            do {
                let users = try await firestoreService.searchUsers(query: query)
                print("🆔 Current user ID: \(authService.currentUser?.id ?? "nil")")
                for user in users {
                    print("🆔 Found user ID: \(user.id ?? "nil") - Name: \(user.displayName)")
                }
                // Filter out current user
                let filtered = users.filter { $0.id != authService.currentUser?.id }
                print("📱 Updating UI with \(filtered.count) users")
                searchResults = filtered
            } catch {
                print("❌ Error searching users: \(error.localizedDescription)")
            }
            isSearching = false
        }
    }
    
    private func startChat(with user: User) {
        print("🚀 Starting chat with user: \(user.displayName) (ID: \(user.id ?? "nil"))")
        Task {
            do {
                let conversation = try await viewModel.createDirectConversation(with: user)
                print("✅ Created/found conversation: \(conversation.id ?? "nil")")
                dismiss()
            } catch {
                print("❌ Error creating conversation: \(error.localizedDescription)")
            }
        }
    }
}

