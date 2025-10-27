//
//  CreateBroadcastListView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI
import FirebaseFirestore

struct CreateBroadcastListView: View {
    @ObservedObject var viewModel: BroadcastViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var listName = ""
    @State private var searchText = ""
    @State private var selectedUserIds: Set<String> = []
    @State private var availableUsers: [User] = []
    @State private var showNameInput = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let firestoreService = FirestoreService()
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return availableUsers
        }
        return availableUsers.filter { user in
            user.displayName.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selected count header
                if !selectedUserIds.isEmpty {
                    HStack {
                        Text("\(selectedUserIds.count)/256 selected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search name or number", text: $searchText)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                
                // User list
                List(filteredUsers) { user in
                    Button {
                        toggleUserSelection(userId: user.id ?? "")
                    } label: {
                        HStack {
                            // Avatar
                            UserAvatarView(
                                profilePictureUrl: user.profilePictureUrl,
                                displayName: user.displayName,
                                size: 40
                            )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            // Checkmark
                            if selectedUserIds.contains(user.id ?? "") {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.title3)
                            } else {
                                Circle()
                                    .stroke(Color(.systemGray4), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
            .navigationTitle("New Broadcast List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        showNameInput = true
                    }
                    .disabled(selectedUserIds.isEmpty)
                }
            }
            .sheet(isPresented: $showNameInput) {
                BroadcastListNameInputView(
                    listName: $listName,
                    recipientCount: selectedUserIds.count,
                    onCreate: {
                        createBroadcastList()
                    },
                    onCancel: {
                        showNameInput = false
                    }
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadUsers()
            }
        }
    }
    
    private func toggleUserSelection(userId: String) {
        if selectedUserIds.contains(userId) {
            selectedUserIds.remove(userId)
        } else {
            if selectedUserIds.count < 256 {
                selectedUserIds.insert(userId)
            }
        }
    }
    
    private func loadUsers() async {
        do {
            // Use FirestoreService to properly load users with IDs
            var users = try await firestoreService.fetchAllUsers()
            
            // Filter out current user
            if let currentUserId = viewModel.authService.currentUser?.id {
                users.removeAll { $0.id == currentUserId }
            }
            
            availableUsers = users
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func createBroadcastList() {
        Task {
            do {
                try await viewModel.createBroadcastList(
                    name: listName,
                    recipientIds: Array(selectedUserIds)
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct BroadcastListNameInputView: View {
    @Binding var listName: String
    let recipientCount: Int
    let onCreate: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("List Name", text: $listName)
                } header: {
                    Text("Name")
                } footer: {
                    Text("This broadcast list will send messages to \(recipientCount) recipients.")
                }
            }
            .navigationTitle("Broadcast List Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate()
                    }
                    .disabled(listName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    CreateBroadcastListView(viewModel: BroadcastViewModel(authService: AuthService()))
}

