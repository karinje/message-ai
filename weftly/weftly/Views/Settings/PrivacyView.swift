//
//  PrivacyView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI

struct PrivacyView: View {
    @ObservedObject var viewModel: PrivacyViewModel
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: $viewModel.lastSeenEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last seen and online")
                            .font(.body)
                        Text("If you don't share your Last Seen and Online, you won't be able to see other people's Last Seen and Online.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Who can see my personal info")
            }
            
            Section {
                Toggle(isOn: $viewModel.readReceiptsEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Read receipts")
                            .font(.body)
                        Text("If you don't share your Read Receipts, you won't be able to see other people's Read Receipts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("Read receipts are always sent for group chats.")
                    .font(.caption)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(.blue)
                        Text("Privacy Settings")
                            .font(.headline)
                    }
                    
                    Text("These privacy controls follow a reciprocal model similar to WhatsApp. When you turn off a setting, you also won't be able to see that information for others.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        PrivacyView(viewModel: PrivacyViewModel(authService: AuthService()))
    }
}

