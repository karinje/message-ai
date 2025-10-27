//
//  UserAvatarView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/27/25.
//

import SwiftUI
import NukeUI
import Nuke

struct UserAvatarView: View {
    let profilePictureUrl: String?
    let displayName: String
    let size: CGFloat
    let showOnlineIndicator: Bool
    let isOnline: Bool
    
    init(
        profilePictureUrl: String?,
        displayName: String,
        size: CGFloat = 50,
        showOnlineIndicator: Bool = false,
        isOnline: Bool = false
    ) {
        self.profilePictureUrl = profilePictureUrl
        self.displayName = displayName
        self.size = size
        self.showOnlineIndicator = showOnlineIndicator
        self.isOnline = isOnline
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar
            if let urlString = profilePictureUrl,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                // Remote profile picture - show initials immediately, load silently
                ZStack {
                    initialsAvatar
                    
                    LazyImage(url: url) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: size, height: size)
                                .clipShape(Circle())
                                .transition(.opacity)
                        }
                    }
                    .processors([.resize(size: CGSize(width: size * 2, height: size * 2))])
                    .priority(.high)
                }
            } else {
                // Fallback to initials
                initialsAvatar
            }
            
            // Online indicator
            if showOnlineIndicator && isOnline {
                Circle()
                    .fill(Color.green)
                    .frame(width: size * 0.24, height: size * 0.24)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: size * 0.04)
                    )
            }
        }
    }
    
    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: size, height: size)
            
            Text(initials)
                .font(.system(size: size * 0.4))
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
        }
    }
    
    private var initials: String {
        let words = displayName.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}

#Preview {
    VStack(spacing: 20) {
        UserAvatarView(
            profilePictureUrl: nil,
            displayName: "John Doe",
            size: 50,
            showOnlineIndicator: true,
            isOnline: true
        )
        
        UserAvatarView(
            profilePictureUrl: nil,
            displayName: "Jane Smith",
            size: 40,
            showOnlineIndicator: false,
            isOnline: false
        )
        
        UserAvatarView(
            profilePictureUrl: nil,
            displayName: "Bob",
            size: 30
        )
    }
}

