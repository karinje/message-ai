//
//  UpdatesView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI

struct UpdatesView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                
                // Title
                Text("Digest")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Description
                VStack(spacing: 12) {
                    Text("Coming Soon")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("AI-powered insights from your conversations: upcoming events, pending RSVPs, deadlines, and group decisions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Feature Sections Preview
                VStack(alignment: .leading, spacing: 16) {
                    DigestFeatureRow(icon: "calendar", title: "Upcoming Events", description: "Auto-extracted from messages")
                    DigestFeatureRow(icon: "hand.raised", title: "Pending RSVPs", description: "Track who's responded")
                    DigestFeatureRow(icon: "alarm", title: "Deadlines", description: "Never miss a commitment")
                    DigestFeatureRow(icon: "lightbulb", title: "Group Decisions", description: "Summaries of what was decided")
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationTitle("Digest")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct DigestFeatureRow: View {
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
    UpdatesView()
}

