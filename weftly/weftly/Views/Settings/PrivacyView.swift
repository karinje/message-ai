//
//  PrivacyView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI

struct PrivacyView: View {
    @ObservedObject var viewModel: PrivacyViewModel
    
    // Computed properties to invert the logic for UI display
    private var lastSeenPrivacyEnabled: Binding<Bool> {
        Binding(
            get: { !viewModel.lastSeenEnabled },
            set: { viewModel.lastSeenEnabled = !$0 }
        )
    }
    
    private var readReceiptsPrivacyEnabled: Binding<Bool> {
        Binding(
            get: { !viewModel.readReceiptsEnabled },
            set: { viewModel.readReceiptsEnabled = !$0 }
        )
    }
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: lastSeenPrivacyEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hide last seen and online")
                            .font(.body)
                        Text("When enabled, you won't share your Last Seen and Online status, and you won't be able to see others' either.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Privacy Controls")
            }
            
            Section {
                Toggle(isOn: readReceiptsPrivacyEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hide read receipts")
                            .font(.body)
                        Text("When enabled, you won't send Read Receipts, and you won't be able to see others' either.")
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

