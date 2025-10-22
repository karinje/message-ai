//
//  ChatListView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel: ChatListViewModel
    @ObservedObject var authService: AuthService
    @State private var showNewChat = false
    @State private var showSearch = false
    
    init(authService: AuthService) {
        self.authService = authService
        _viewModel = StateObject(wrappedValue: ChatListViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(destination: ChatDetailView(conversation: conversation, authService: authService, chatListViewModel: viewModel)) {
                        ConversationRow(conversation: conversation, currentUserId: authService.currentUser?.id ?? "")
                    }
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            Task {
                                try? authService.signOut()
                            }
                        } label: {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Group {
                            if let user = authService.currentUser {
                                Text(user.displayName.prefix(2).uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 32, height: 32)
                            }
                        }
                        .id(authService.currentUser?.id ?? "loading")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showSearch = true
                        } label: {
                            Label("New Direct Chat", systemImage: "person.badge.plus")
                        }
                        
                        Button {
                            showNewChat = true
                        } label: {
                            Label("New Group Chat", systemImage: "person.3.fill")
                        }
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                UserSearchView(authService: authService, viewModel: viewModel)
            }
            .sheet(isPresented: $showNewChat) {
                NewGroupView(authService: authService, viewModel: viewModel)
            }
            .onAppear {
                print("📱 ChatListView appeared, user: \(authService.currentUser?.displayName ?? "nil")")
                if authService.currentUser != nil {
                    viewModel.startListening()
                }
            }
            .onDisappear {
                viewModel.stopListening()
            }
            .onChange(of: authService.currentUser) { _, newUser in
                print("📱 Auth state changed, user: \(newUser?.displayName ?? "nil")")
                viewModel.stopListening()
                if newUser != nil {
                    viewModel.startListening()
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(conversation.displayName(for: currentUserId).prefix(2).uppercased())
                            .font(.headline)
                            .foregroundStyle(.blue)
                    )
                
                // Online indicator for direct chats
                if conversation.type == .direct {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayName(for: currentUserId))
                        .font(.headline)
                    
                    Spacer()
                    
                    if let lastMessageTime = conversation.lastMessageTime {
                        Text(lastMessageTime.timeAgoDisplay())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

