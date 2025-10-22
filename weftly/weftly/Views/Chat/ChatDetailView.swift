//
//  ChatDetailView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI
import PhotosUI
import SwiftData
import NukeUI

struct ChatDetailView: View {
    let conversation: Conversation
    let authService: AuthService
    let chatListViewModel: ChatListViewModel?
    
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var networkMonitor = NetworkMonitor()
    @Environment(\.modelContext) private var modelContext
    
    @State private var showImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    
    init(conversation: Conversation, authService: AuthService, chatListViewModel: ChatListViewModel? = nil) {
        self.conversation = conversation
        self.authService = authService
        self.chatListViewModel = chatListViewModel
        
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
            if conversation.type == .group {
                GroupInfoHeader(
                    title: conversation.groupName ?? "Group",
                    members: participantNames,
                    currentUserName: authService.currentUser?.displayName
                )
            }
            
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
                Divider()
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
            VStack(spacing: 8) {
                if let pendingData = viewModel.pendingImageData, let image = UIImage(data: pendingData) {
                    HStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                Button(action: { viewModel.pendingImageData = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .offset(x: 8, y: -8)
                            , alignment: .topTrailing)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(viewModel.pendingImageData == nil ? .blue : .gray)
                    }
                    .disabled(viewModel.pendingImageData != nil)
                    
                    TextField("Message", text: $viewModel.messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)
                        .onChange(of: viewModel.messageText) { _, _ in
                            Task { @MainActor in
                                viewModel.handleTextChange()
                            }
                        }
                        .submitLabel(.send)
                        .onSubmit {
                            if canSendMessage {
                                viewModel.sendMessage()
                            }
                        }
                    
                    Button(action: {
                        viewModel.sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(canSendMessage ? .blue : .gray)
                    }
                    .disabled(!canSendMessage)
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle(conversation.displayName(for: authService.currentUser?.id ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startListening()
            viewModel.retryPendingMessages()
            if let listViewModel = chatListViewModel {
                listViewModel.setActiveConversation(id: conversation.id)
            }
        }
        .onDisappear {
            viewModel.stopListening()
            if let listViewModel = chatListViewModel {
                listViewModel.setActiveConversation(id: nil)
            }
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
    
    private var participantNames: [String] {
        let currentUserId = authService.currentUser?.id ?? ""
        let others = conversation.participantNames.filter { $0.key != currentUserId }
            .sorted { $0.value.lowercased() < $1.value.lowercased() }
            .map { $0.value }
        if let currentName = authService.currentUser?.displayName {
            return [currentName] + others
        }
        return others
    }
}

extension ChatDetailView {
    private var canSendMessage: Bool {
        let trimmed = viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty || viewModel.pendingImageData != nil
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        let hasText = !message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLocalImage = message.localImageData != nil
        let hasRemoteImage = (message.imageUrl ?? "").isEmpty == false
        let hasImage = hasLocalImage || hasRemoteImage
        
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser && message.senderName.isEmpty == false {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    if let data = message.localImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else if let imageUrl = message.imageUrl,
                              !imageUrl.isEmpty {
                        RemoteImageView(url: imageUrl)
                            .frame(maxWidth: 250)
                    }
                    
                    if hasText {
                        Text(message.text)
                            .foregroundStyle(isCurrentUser ? .white : .primary)
                    }
                }
                .padding(hasText ? 12 : 0)
                .background(hasText ? (isCurrentUser ? Color.blue : Color(.systemGray6)) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: hasText ? 16 : 0))
                
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
        .padding(.vertical, 4)
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

struct GroupInfoHeader: View {
    let title: String
    let members: [String]
    let currentUserName: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(members, id: \.self) { name in
                        HStack(spacing: 6) {
                            Text(initials(for: name))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Color.blue))
                            Text(displayName(for: name))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(.thinMaterial)
        .overlay(Divider(), alignment: .bottom)
    }
    
    private func initials(for name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .map { String($0.first ?? Character("?")) }
            .joined()
            .uppercased()
    }
    
    private func displayName(for name: String) -> String {
        if let current = currentUserName, name == current {
            return "You"
        }
        return name
    }
}

struct RemoteImageView: View {
    let url: String
    
    var body: some View {
        LazyImage(url: URL(string: url)) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if state.isLoading {
                ProgressView()
                    .frame(width: 200, height: 200)
            } else {
                Color(.systemGray5)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

