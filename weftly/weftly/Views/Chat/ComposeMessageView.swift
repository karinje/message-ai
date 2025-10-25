//
//  ComposeMessageView.swift
//  weftly
//
//  Created for composing first message to a contact
//

import SwiftUI
import SwiftData

struct ComposeMessageView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let recipient: User
    let conversation: Conversation
    let authService: AuthService
    let networkMonitor: NetworkMonitor
    let onDismiss: (() -> Void)?
    
    @State private var messageText = ""
    @State private var isSending = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Recipient info
                VStack(spacing: 8) {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(recipient.displayName.prefix(2).uppercased())
                                .font(.title2)
                                .foregroundStyle(.blue)
                        )
                    
                    Text(recipient.displayName)
                        .font(.headline)
                    
                    Text(recipient.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Message input
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Message \(recipient.displayName.split(separator: " ").first ?? "")", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .lineLimit(1...5)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty || isSending)
                }
                .padding()
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss?()
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty,
              let currentUser = authService.currentUser,
              let userId = currentUser.id,
              let conversationId = conversation.id else { return }
        
        isSending = true
        let text = messageText
        messageText = ""
        
        let message = Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: userId,
            senderName: currentUser.displayName,
            senderProfileUrl: currentUser.profilePictureUrl,
            text: text,
            timestamp: Date(),
            status: networkMonitor.isConnected ? .sending : .pending,
            readBy: [userId]
        )
        
        // Save to SwiftData immediately
        do {
            try MessageCacheService.shared.saveMessage(message, currentUserId: userId, in: modelContext)
            print("💾 First message saved to cache")
        } catch {
            print("❌ Error saving message: \(error)")
        }
        
        // Send to Firestore
        Task {
            if networkMonitor.isConnected {
                do {
                    let sentMessage = try await FirestoreService().sendMessage(message)
                    try? MessageCacheService.shared.saveMessage(sentMessage, currentUserId: userId, in: modelContext)
                    print("✅ First message sent")
                    
                    await MainActor.run {
                        dismiss()
                        onDismiss?()
                    }
                } catch {
                    print("❌ Error sending message: \(error)")
                    // Keep as pending, will retry on reconnect
                    var pendingMsg = message
                    pendingMsg.status = .pending
                    try? MessageCacheService.shared.saveMessage(pendingMsg, currentUserId: userId, in: modelContext)
                    
                    await MainActor.run {
                        dismiss()
                        onDismiss?()
                    }
                }
            } else {
                // Offline - message already saved as pending
                await MainActor.run {
                    dismiss()
                    onDismiss?()
                }
            }
        }
    }
}

