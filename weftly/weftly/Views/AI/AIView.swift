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
                    
                    Text("Smart calendar extraction, decision summarization, priority detection, RSVP tracking, and deadline reminders")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Feature List
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "calendar.badge.clock", title: "Calendar Extraction", description: "Auto-detect dates and events")
                    FeatureRow(icon: "list.bullet.clipboard", title: "Decision Summary", description: "Summarize group decisions")
                    FeatureRow(icon: "exclamationmark.triangle", title: "Priority Detection", description: "Flag urgent messages")
                    FeatureRow(icon: "hand.raised", title: "RSVP Tracking", description: "Track event confirmations")
                    FeatureRow(icon: "bell.badge", title: "Deadline Reminders", description: "Never miss a deadline")
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationTitle("AI")
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

