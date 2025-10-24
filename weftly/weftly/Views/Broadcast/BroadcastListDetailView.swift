//
//  BroadcastListDetailView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI
import FirebaseFirestore

struct BroadcastListDetailView: View {
    @ObservedObject var viewModel: BroadcastViewModel
    let broadcastList: BroadcastList
    
    @State private var messageText = ""
    @State private var recipients: [User] = []
    @State private var isSending = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 0) {
            // Recipients List
            List {
                Section {
                    ForEach(recipients) { recipient in
                        HStack {
                            // Avatar
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(recipient.displayName.prefix(2).uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recipient.displayName)
                                    .font(.body)
                                Text(recipient.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Recipients (\(recipients.count))")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("About Broadcast Lists")
                                .font(.headline)
                        }
                        
                        Text("Messages sent to this broadcast list will be delivered as individual chats to each recipient. Recipients won't know they're part of a broadcast list.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Message Input
            VStack(spacing: 0) {
                Divider()
                
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Broadcast message", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .lineLimit(1...5)
                    
                    Button {
                        sendBroadcast()
                    } label: {
                        if isSending {
                            ProgressView()
                                .frame(width: 36, height: 36)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .green)
                        }
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle(broadcastList.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await loadRecipients()
        }
    }
    
    private func loadRecipients() async {
        do {
            var loadedRecipients: [User] = []
            for recipientId in broadcastList.recipientIds {
                let doc = try await db.collection("users").document(recipientId).getDocument()
                if let user = try? doc.data(as: User.self) {
                    loadedRecipients.append(user)
                }
            }
            recipients = loadedRecipients
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func sendBroadcast() {
        guard let listId = broadcastList.id else { return }
        
        isSending = true
        
        Task {
            do {
                try await viewModel.sendBroadcastMessage(
                    listId: listId,
                    messageText: messageText
                )
                messageText = ""
                isSending = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isSending = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        BroadcastListDetailView(
            viewModel: BroadcastViewModel(authService: AuthService()),
            broadcastList: BroadcastList(
                name: "Soccer Parents",
                recipientIds: [],
                messageCount: 0
            )
        )
    }
}

