//
//  ProfileView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var authService: AuthService
    @State private var isEditingProfile = false
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingImage = false
    @State private var uploadError: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Avatar Section
                Section {
                    VStack(spacing: 16) {
                        // Large Avatar
                        ZStack {
                            if let profilePictureUrl = authService.currentUser?.profilePictureUrl,
                               let url = URL(string: profilePictureUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                            } else if let user = authService.currentUser {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 200, height: 200)
                                    .overlay(
                                        Text(user.displayName.prefix(2).uppercased())
                                            .font(.system(size: 80))
                                            .fontWeight(.bold)
                                            .foregroundStyle(.blue)
                                    )
                            }
                            
                            // Upload indicator
                            if isUploadingImage {
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 200, height: 200)
                                    .overlay(
                                        ProgressView()
                                            .tint(.white)
                                    )
                            }
                        }
                        
                        // Edit Button
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text("Edit")
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }
                        .disabled(isUploadingImage)
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                await uploadProfilePicture(newItem)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
                
                // Profile Information
                Section {
                    // Display Name
                    HStack {
                        Text("Name")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(authService.currentUser?.displayName ?? "")
                    }
                    
                    // About
                    NavigationLink {
                        EditAboutView(authService: authService)
                    } label: {
                        HStack {
                            Text("About")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(authService.currentUser?.about ?? "Hey there! I am using Weftly.")
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                    }
                    
                    // Phone Number
                    HStack {
                        Text("Phone")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(authService.currentUser?.phoneNumber ?? "Not set")
                    }
                    
                    // Email
                    HStack {
                        Text("Email")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(authService.currentUser?.email ?? "")
                            .foregroundStyle(.primary)
                    }
                }
                
                // Error Message
                if let error = uploadError {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
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
        }
    }
    
    // MARK: - Profile Picture Upload
    
    private func uploadProfilePicture(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isUploadingImage = true
        uploadError = nil
        
        do {
            // Load image data
            guard let imageData = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: imageData) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
            }
            
            // Upload to Firebase Storage
            guard let userId = authService.currentUser?.id else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
            }
            
            let storageService = StorageService()
            let downloadURL = try await storageService.uploadProfilePicture(uiImage, userId: userId)
            
            // Update Firestore user document
            try await authService.updateProfilePicture(url: downloadURL)
            
        } catch {
            print("[ProfileView] Upload failed: \(error.localizedDescription)")
            uploadError = "Failed to upload profile picture"
        }
        
        isUploadingImage = false
        selectedPhotoItem = nil
    }
}

#Preview {
    ProfileView(authService: AuthService())
}

