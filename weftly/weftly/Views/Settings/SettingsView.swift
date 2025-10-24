//
//  SettingsView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var authService: AuthService
    @State private var showSignOutAlert = false
    @StateObject private var listsViewModel: ListsViewModel
    @StateObject private var privacyViewModel: PrivacyViewModel
    @StateObject private var broadcastViewModel: BroadcastViewModel
    
    init(authService: AuthService) {
        self.authService = authService
        _listsViewModel = StateObject(wrappedValue: ListsViewModel(authService: authService))
        _privacyViewModel = StateObject(wrappedValue: PrivacyViewModel(authService: authService))
        _broadcastViewModel = StateObject(wrappedValue: BroadcastViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section {
                    if let user = authService.currentUser {
                        VStack(spacing: 16) {
                            // Profile Picture
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(user.displayName.prefix(2).uppercased())
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                )
                            
                            // Display Name
                            Text(user.displayName)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            // Email
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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
        }
    }
}

#Preview {
    SettingsView(authService: AuthService())
}

