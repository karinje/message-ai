//
//  AIView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI

struct AIView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                
                // Title
                Text("AI Assistant")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Description
                VStack(spacing: 12) {
                    Text("Coming Soon")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Chat with your intelligent assistant to search messages, translate conversations, get summaries, and more")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Quick Actions Preview
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "magnifyingglass", title: "Search Messages", description: "Find anything in your chats")
                    FeatureRow(icon: "text.bubble", title: "Summarize Conversations", description: "Get quick summaries")
                    FeatureRow(icon: "globe", title: "Translate", description: "Translate any message")
                    FeatureRow(icon: "calendar", title: "Show Calendar", description: "View upcoming events")
                    FeatureRow(icon: "list.bullet", title: "Check RSVPs", description: "See who's responded")
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationTitle("Assistant")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AIView()
}

