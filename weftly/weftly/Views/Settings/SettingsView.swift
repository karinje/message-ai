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
                
                // Lists Section (Placeholder for PR #13)
                Section {
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(.blue)
                            .frame(width: 30)
                        Text("Lists")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                } header: {
                    Text("Organization")
                } footer: {
                    Text("Create custom lists to organize your chats. Coming soon.")
                }
                
                // Broadcast Messages Section (Placeholder for PR #14)
                Section {
                    HStack {
                        Image(systemName: "megaphone")
                            .foregroundStyle(.blue)
                            .frame(width: 30)
                        Text("Broadcast messages")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                } footer: {
                    Text("Send a message to multiple contacts at once. Coming soon.")
                }
                
                // Privacy Section (Placeholder for PR #13)
                Section {
                    HStack {
                        Image(systemName: "lock")
                            .foregroundStyle(.blue)
                            .frame(width: 30)
                        Text("Privacy")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Control your last seen, read receipts, and online status. Coming soon.")
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
                        try? authService.signOut()
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

