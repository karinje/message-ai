//
//  NewGroupView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI
import SwiftData

struct NewGroupView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let authService: AuthService
    let viewModel: ChatListViewModel
    let networkMonitor: NetworkMonitor
    
    @State private var groupName = ""
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var selectedUsers: Set<String> = []
    @State private var isCreating = false
    @State private var showChatView = false
    @State private var createdConversation: Conversation?
    
    private let firestoreService = FirestoreService()
    
    // Cache selected user models so they persist across search changes
    @State private var selectedUserDetails: [String: User] = [:]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Group name input
                TextField("Group Name", text: $groupName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                // Selected users
                if !selectedUsers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(selectedUsers), id: \.self) { userId in
                                if let user = searchResults.first(where: { $0.id == userId }) {
                                    VStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Text(user.displayName.prefix(2).uppercased())
                                                    .font(.caption)
                                                    .foregroundStyle(.blue)
                                            )
                                            .overlay(alignment: .topTrailing) {
                                                Button {
                                                    selectedUsers.remove(userId)
                                                    selectedUserDetails.removeValue(forKey: userId)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundStyle(.gray)
                                                        .background(Circle().fill(Color.white))
                                                }
                                                .offset(x: 8, y: -8)
                                            }
                                        
                                        Text(user.displayName)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                
                // User search
                List {
                    ForEach(searchResults) { user in
                        Button {
                            if let userId = user.id {
                                if selectedUsers.contains(userId) {
                                    selectedUsers.remove(userId)
                                    selectedUserDetails.removeValue(forKey: userId)
                                } else {
                                    selectedUsers.insert(userId)
                                    selectedUserDetails[userId] = user
                                }
                            }
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
                                
                                if let userId = user.id, selectedUsers.contains(userId) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Group")
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty || selectedUsers.count < 2 || isCreating)
                }
            }
            .sheet(isPresented: $showChatView, onDismiss: {
                dismiss()  // Also dismiss group creation view
            }) {
                if let conversation = createdConversation {
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
        
        Task {
            do {
                let users = try await firestoreService.searchUsers(query: query)
                searchResults = users.filter { $0.id != authService.currentUser?.id }
            } catch {
                print("Error searching users: \(error.localizedDescription)")
            }
        }
    }
    
    private func createGroup() {
        isCreating = true
        print("👥 Creating group with selected users: \(selectedUsers)")
        
        Task {
            do {
                let participants = selectedUsers.compactMap { selectedUserDetails[$0] }
                print("👥 Resolved participants: \(participants.map { $0.displayName })")
                
                let conversation = try await viewModel.createGroupConversation(name: groupName, participants: participants)
                
                await MainActor.run {
                    createdConversation = conversation
                    showChatView = true
                    // Don't dismiss - let the sheet handle dismissal
                }
            } catch {
                print("Error creating group: \(error.localizedDescription)")
                await MainActor.run {
                    isCreating = false
                }
            }
        }
    }
}

