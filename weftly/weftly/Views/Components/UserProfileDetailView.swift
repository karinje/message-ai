//
//  UserProfileDetailView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/27/25.
//

import SwiftUI
import FirebaseFirestore

struct UserProfileDetailView: View {
    let userId: String
    @State private var user: User?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading profile...")
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.secondary)
                    }
                } else if let user = user {
                    profileContent(user: user)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadUserProfile()
            }
        }
    }
    
    private func profileContent(user: User) -> some View {
        List {
            // Avatar Section
            Section {
                VStack(spacing: 16) {
                    UserAvatarView(
                        profilePictureUrl: user.profilePictureUrl,
                        displayName: user.displayName,
                        size: 200
                    )
                    
                    Text(user.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .listRowBackground(Color.clear)
            
            // Profile Information
            Section {
                // About
                HStack {
                    Text("About")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(user.about ?? "Hey there! I am using Weftly.")
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)
                }
                
                // Phone Number (if available)
                if let phoneNumber = user.phoneNumber {
                    HStack {
                        Text("Phone")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(phoneNumber)
                    }
                }
                
                // Email (if available)
                HStack {
                    Text("Email")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(user.email)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
        }
    }
    
    private func loadUserProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let db = Firestore.firestore()
            let document = try await db.collection("users").document(userId).getDocument()
            
            if let fetchedUser = try? document.data(as: User.self) {
                self.user = fetchedUser
            } else {
                errorMessage = "Failed to load user profile"
            }
        } catch {
            print("❌ Error loading user profile: \(error)")
            errorMessage = "Failed to load user profile"
        }
        
        isLoading = false
    }
}

#Preview {
    UserProfileDetailView(userId: "sample-user-id")
}

