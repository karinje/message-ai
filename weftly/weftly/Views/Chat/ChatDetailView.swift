//
//  ChatDetailView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI
import PhotosUI
import SwiftData

struct ChatDetailView: View {
    let conversation: Conversation
    let authService: AuthService
    
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var networkMonitor = NetworkMonitor()
    @Environment(\.modelContext) private var modelContext
    
    @State private var showImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    
    init(conversation: Conversation, authService: AuthService) {
        self.conversation = conversation
        self.authService = authService
        
        // Note: In real app, we'd inject modelContext properly
        // For now, this will be set up in the app entry point
        let container = try! ModelContainer(for: PendingMessage.self)
        _viewModel = StateObject(wrappedValue: ChatViewModel(
            conversation: conversation,
            authService: authService,
            networkMonitor: NetworkMonitor(),
            modelContext: container.mainContext
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isCurrentUser: message.senderId == authService.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Typing indicator
            if let typingText = viewModel.typingUsersText {
                HStack {
                    Text(typingText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    Spacer()
                }
            }
            
            // Network status
            if !networkMonitor.isConnected {
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundStyle(.red)
                    Text("No connection - messages will send when online")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
            }
            
            // Input area
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                
                TextField("Message", text: $viewModel.messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .onChange(of: viewModel.messageText) { _, _ in
                        viewModel.handleTextChange()
                    }
                
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.messageText.isEmpty ? .gray : .blue)
                }
                .disabled(viewModel.messageText.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(conversation.displayName(for: authService.currentUser?.id ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startListening()
            viewModel.retryPendingMessages()
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .onChange(of: selectedImage) { _, newValue in
            guard let newValue = newValue else { return }
            
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.sendImage(image)
                }
                selectedImage = nil
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Show sender name in group chats
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Message content
                VStack(alignment: .leading, spacing: 8) {
                    if let imageUrl = message.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 250)
                                .cornerRadius(12)
                        } placeholder: {
                            ProgressView()
                                .frame(width: 200, height: 200)
                        }
                    }
                    
                    if !message.text.isEmpty && message.imageUrl == nil {
                        Text(message.text)
                            .foregroundStyle(isCurrentUser ? .white : .primary)
                    }
                }
                .padding(12)
                .background(isCurrentUser ? Color.blue : Color(.systemGray6))
                .cornerRadius(16)
                
                // Status and timestamp
                HStack(spacing: 4) {
                    Text(message.timestamp.timeAgoDisplay())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if isCurrentUser {
                        statusIcon
                    }
                }
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sending:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .delivered:
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        case .read:
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.caption2)
            .foregroundStyle(.blue)
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .font(.caption2)
                .foregroundStyle(.red)
        }
    }
}

