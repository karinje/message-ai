//
//  SettingsView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var authService: AuthService
    @State private var showSignOutAlert = false
    @State private var showDeleteChatsAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showProfileView = false
    @Environment(\.modelContext) private var modelContext
    @StateObject private var listsViewModel: ListsViewModel
    @StateObject private var privacyViewModel: PrivacyViewModel
    @StateObject private var broadcastViewModel: BroadcastViewModel
    @StateObject private var cloudBackupViewModel: CloudBackupViewModel
    
    init(authService: AuthService) {
        self.authService = authService
        _listsViewModel = StateObject(wrappedValue: ListsViewModel(authService: authService))
        _privacyViewModel = StateObject(wrappedValue: PrivacyViewModel(authService: authService))
        _broadcastViewModel = StateObject(wrappedValue: BroadcastViewModel(authService: authService))
        _cloudBackupViewModel = StateObject(wrappedValue: CloudBackupViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section {
                    if let user = authService.currentUser {
                        Button {
                            showProfileView = true
                        } label: {
                            VStack(spacing: 16) {
                                // Profile Picture
                                if let profilePictureUrl = user.profilePictureUrl,
                                   let url = URL(string: profilePictureUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Text(user.displayName.prefix(2).uppercased())
                                                .font(.title)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.blue)
                                        )
                                }
                                
                                // Display Name
                                Text(user.displayName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                // About or Email
                                Text(user.about ?? user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                    }
                } header: {
                    Text("Account")
                }
                
                // Lists Section
                Section {
                    NavigationLink {
                        ListsView(viewModel: listsViewModel)
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            Text("Lists")
                        }
                    }
                } header: {
                    Text("Organization")
                } footer: {
                    Text("Create custom lists to organize your chats.")
                }
                
                // Broadcast Messages Section
                Section {
                    NavigationLink {
                        BroadcastView(viewModel: broadcastViewModel)
                    } label: {
                        HStack {
                            Image(systemName: "megaphone")
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            Text("Broadcast messages")
                        }
                    }
                } footer: {
                    Text("Send a message to multiple contacts at once.")
                }
                
                // Privacy Section
                Section {
                    NavigationLink {
                        PrivacyView(viewModel: privacyViewModel)
                    } label: {
                        HStack {
                            Image(systemName: "lock")
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            Text("Privacy")
                        }
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Control your last seen, read receipts, and online status.")
                }
                
                // Cloud Backup Section
                Section {
                    NavigationLink {
                        CloudBackupView(viewModel: cloudBackupViewModel)
                    } label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            Text("Cloud Backup")
                        }
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Back up your messages to the cloud and restore them if needed.")
                }
                
                // Account Actions
                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .frame(width: 30)
                            Text("Sign Out")
                        }
                    }
                    
                    Button(role: .destructive) {
                        showDeleteChatsAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .frame(width: 30)
                            Text("Delete All Chats")
                        }
                    }
                    
                    Button(role: .destructive) {
                        showDeleteAccountAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "person.slash")
                                .frame(width: 30)
                            Text("Delete Account")
                        }
                    }
                } footer: {
                    Text("Deleting your account will permanently remove all your data and cannot be undone.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authService.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete All Chats", isPresented: $showDeleteChatsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await authService.deleteAllChats(modelContext: modelContext)
                            // Force UI refresh by dismissing and reopening app or reloading data
                            print("✅ Chats deleted - restart app to see changes")
                        } catch {
                            print("❌ Error deleting chats: \(error.localizedDescription)")
                        }
                    }
                }
            } message: {
                Text("This will delete all your LOCAL chat history from this device. This cannot be undone. You may need to restart the app to see changes.")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    showDeleteAccountConfirmation = true
                }
            } message: {
                Text("Delete account? All your data will be permanently removed.")
            }
            .alert("Are You Absolutely Sure?", isPresented: $showDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Account", role: .destructive) {
                    Task {
                        try? await authService.deleteAccount()
                    }
                }
            } message: {
                Text("This cannot be undone. Your account will be permanently deleted.")
            }
            .sheet(isPresented: $showProfileView) {
                ProfileView(authService: authService)
            }
        }
    }
}

#Preview {
    SettingsView(authService: AuthService())
}

