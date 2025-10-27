//
//  BroadcastListDetailView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI
import FirebaseFirestore

struct BroadcastListDetailView: View {
    @ObservedObject var viewModel: BroadcastViewModel
    let broadcastList: BroadcastList
    
    @State private var messageText = ""
    @State private var recipients: [User] = []
    @State private var isSending = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showEditMembers = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 0) {
            // Recipients List
            List {
                Section {
                    ForEach(recipients) { recipient in
                        HStack {
                            // Avatar
                            UserAvatarView(
                                profilePictureUrl: recipient.profilePictureUrl,
                                displayName: recipient.displayName,
                                size: 40
                            )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recipient.displayName)
                                    .font(.body)
                                Text(recipient.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Recipients (\(recipients.count))")
                        Spacer()
                        Button {
                            showEditMembers = true
                        } label: {
                            Text("Edit")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    .textCase(nil)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("About Broadcast Lists")
                                .font(.headline)
                        }
                        
                        Text("Messages sent to this broadcast list will be delivered as individual chats to each recipient. Recipients won't know they're part of a broadcast list.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Message Input
            VStack(spacing: 0) {
                Divider()
                
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Broadcast message", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .lineLimit(1...5)
                    
                    Button {
                        sendBroadcast()
                    } label: {
                        if isSending {
                            ProgressView()
                                .frame(width: 36, height: 36)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .green)
                        }
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle(broadcastList.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditMembers) {
            EditBroadcastMembersView(
                viewModel: viewModel,
                broadcastList: broadcastList,
                currentRecipientIds: Set(broadcastList.recipientIds),
                onUpdate: {
                    Task {
                        await loadRecipients()
                    }
                }
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await loadRecipients()
        }
    }
    
    private func loadRecipients() async {
        do {
            var loadedRecipients: [User] = []
            for recipientId in broadcastList.recipientIds {
                let doc = try await db.collection("users").document(recipientId).getDocument()
                if var user = try? doc.data(as: User.self) {
                    // Ensure ID is set from document ID
                    if user.id == nil {
                        user.id = doc.documentID
                    }
                    loadedRecipients.append(user)
                }
            }
            recipients = loadedRecipients
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func sendBroadcast() {
        guard let listId = broadcastList.id else { return }
        
        isSending = true
        
        Task {
            do {
                try await viewModel.sendBroadcastMessage(
                    listId: listId,
                    messageText: messageText
                )
                messageText = ""
                isSending = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isSending = false
            }
        }
    }
}

struct EditBroadcastMembersView: View {
    @ObservedObject var viewModel: BroadcastViewModel
    let broadcastList: BroadcastList
    @State var currentRecipientIds: Set<String>
    let onUpdate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var availableUsers: [User] = []
    @State private var selectedUserIds: Set<String>
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    private let firestoreService = FirestoreService()
    
    init(viewModel: BroadcastViewModel, broadcastList: BroadcastList, currentRecipientIds: Set<String>, onUpdate: @escaping () -> Void) {
        self.viewModel = viewModel
        self.broadcastList = broadcastList
        self.currentRecipientIds = currentRecipientIds
        self.onUpdate = onUpdate
        _selectedUserIds = State(initialValue: currentRecipientIds)
    }
    
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
                HStack {
                    Text("\(selectedUserIds.count)/256 selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
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
            .navigationTitle("Edit Recipients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(selectedUserIds.isEmpty || selectedUserIds == currentRecipientIds)
                }
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
    
    private func saveChanges() {
        Task {
            do {
                guard let listId = broadcastList.id else { return }
                try await viewModel.updateBroadcastList(
                    listId: listId,
                    name: nil,
                    recipientIds: Array(selectedUserIds)
                )
                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        BroadcastListDetailView(
            viewModel: BroadcastViewModel(authService: AuthService()),
            broadcastList: BroadcastList(
                name: "Soccer Parents",
                recipientIds: [],
                messageCount: 0
            )
        )
    }
}

