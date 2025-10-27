//
//  UserSelectionView.swift
//  weftly
//
//  Created for List creation - shows all users for multi-selection
//

import SwiftUI

struct UserSelectionView: View {
    @Environment(\.dismiss) var dismiss
    let authService: AuthService
    @Binding var selectedUserIds: Set<String>
    
    @State private var searchText = ""
    @State private var allUsers: [User] = []
    @State private var isLoading = false
    
    private let firestoreService = FirestoreService()
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return allUsers
        }
        return allUsers.filter { user in
            user.displayName.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading users...")
                } else if allUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No users found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(filteredUsers) { user in
                            Button {
                                toggleSelection(for: user)
                            } label: {
                                HStack(spacing: 12) {
                                    // Avatar
                                    UserAvatarView(
                                        profilePictureUrl: user.profilePictureUrl,
                                        displayName: user.displayName,
                                        size: 40
                                    )
                                    
                                    // User info
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.displayName)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(user.email)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Checkmark
                                    if let userId = user.id, selectedUserIds.contains(userId) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.title3)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                            .font(.title3)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Users")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search users")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(selectedUserIds.isEmpty)
                }
            }
            .task {
                await loadAllUsers()
            }
        }
    }
    
    private func toggleSelection(for user: User) {
        guard let userId = user.id else { return }
        
        if selectedUserIds.contains(userId) {
            selectedUserIds.remove(userId)
        } else {
            selectedUserIds.insert(userId)
        }
    }
    
    private func loadAllUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch all users from Firestore
            let users = try await firestoreService.fetchAllUsers()
            
            // Filter out current user
            let filtered = users.filter { $0.id != authService.currentUser?.id }
            
            await MainActor.run {
                allUsers = filtered
            }
        } catch {
            print("❌ Error loading users: \(error.localizedDescription)")
        }
    }
}

#Preview {
    UserSelectionView(
        authService: AuthService(),
        selectedUserIds: .constant([])
    )
}

