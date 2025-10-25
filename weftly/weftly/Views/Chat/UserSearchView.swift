//
//  UserSearchView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI
import SwiftData

struct UserSearchView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let authService: AuthService
    let viewModel: ChatListViewModel
    let networkMonitor: NetworkMonitor
    
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var selectedUser: User?
    @State private var selectedConversation: Conversation?
    @State private var showComposeView = false
    @State private var showChatView = false
    
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
            .sheet(isPresented: $showComposeView) {
                if let user = selectedUser, let conversation = selectedConversation {
                    ComposeMessageView(
                        recipient: user,
                        conversation: conversation,
                        authService: authService,
                        networkMonitor: networkMonitor,
                        onDismiss: {
                            dismiss()  // Also dismiss search view
                        }
                    )
                }
            }
            .sheet(isPresented: $showChatView, onDismiss: {
                dismiss()  // Also dismiss search view
            }) {
                if let conversation = selectedConversation {
                    ChatDetailView(
                        conversation: conversation,
                        authService: authService,
                        modelContext: modelContext
                    )
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
                
                // Check if conversation has messages in SwiftData
                if let conversationId = conversation.id {
                    let messages = try? MessageCacheService.shared.fetchMessages(for: conversationId, in: modelContext)
                    
                    await MainActor.run {
                        selectedUser = user
                        selectedConversation = conversation
                        
                        if let messages = messages, !messages.isEmpty {
                            // Has messages → go to chat
                            print("✅ Conversation has messages → ChatDetailView")
                            showChatView = true
                        } else {
                            // No messages → compose first message
                            print("✅ No messages → ComposeMessageView")
                            showComposeView = true
                        }
                        // Don't dismiss - let the sheet handle dismissal
                    }
                }
            } catch {
                print("❌ Error creating conversation: \(error.localizedDescription)")
            }
        }
    }
}

