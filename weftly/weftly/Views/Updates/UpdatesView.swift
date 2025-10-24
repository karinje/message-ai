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
                Image(systemName: "circle.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.green.gradient)
                
                // Title
                Text("Updates")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Description
                VStack(spacing: 12) {
                    Text("No updates yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Share photos, videos, and status updates that disappear after 24 hours")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Add Status Button (disabled for now)
                Button(action: {}) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add status")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(true)
                .opacity(0.5)
                .padding(.horizontal, 32)
                
                Text("Coming soon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .navigationTitle("Updates")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    UpdatesView()
}

