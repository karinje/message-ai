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
import Nuke

struct ChatDetailView: View {
    let conversation: Conversation
    let authService: AuthService
    let chatListViewModel: ChatListViewModel?
    
    @StateObject private var networkMonitor: NetworkMonitor
    @StateObject private var viewModel: ChatViewModel
    
    @State private var showImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    
    init(conversation: Conversation, authService: AuthService, chatListViewModel: ChatListViewModel? = nil, modelContext: ModelContext) {
        self.conversation = conversation
        self.authService = authService
        self.chatListViewModel = chatListViewModel
        let monitor = NetworkMonitor()
        _networkMonitor = StateObject(wrappedValue: monitor)
        _viewModel = StateObject(wrappedValue: ChatViewModel(
            conversation: conversation,
            authService: authService,
            networkMonitor: monitor,
            modelContext: modelContext
        ))
    }
    
    var body: some View {
        contentView(viewModel: viewModel)
    }
    
    @ViewBuilder
    private func contentView(viewModel: ChatViewModel) -> some View {
        VStack(spacing: 0) {
            groupHeaderView(viewModel: viewModel)
            messagesListView(viewModel: viewModel)
            typingIndicatorView(viewModel: viewModel)
            networkStatusView()
            inputAreaView(viewModel: viewModel)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if viewModel.currentConversation.type == .direct {
                    // Show custom header with online/last seen for 1:1 chats
                    ChatHeaderView(
                        displayName: viewModel.currentConversation.displayName(for: authService.currentUser?.id ?? ""),
                        otherUserId: otherParticipantId(for: viewModel),
                        currentUserId: authService.currentUser?.id
                    )
                } else {
                    // Show simple title for groups
                    Text(viewModel.currentConversation.displayName(for: authService.currentUser?.id ?? ""))
                        .font(.headline)
                }
            }
        }
        .onAppear {
            viewModel.startListening()
            viewModel.retryPendingMessages()
            if let listViewModel = chatListViewModel {
                listViewModel.setActiveConversation(id: viewModel.currentConversation.id)
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
            
            Task { @MainActor in
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.sendImage(image)
                }
                selectedImage = nil
            }
        }
    }
    
    // MARK: - Sub-views
    
    @ViewBuilder
    private func groupHeaderView(viewModel: ChatViewModel) -> some View {
        if viewModel.currentConversation.type == .group {
            GroupInfoHeader(
                title: viewModel.currentConversation.groupName ?? "Group",
                members: participantNames(for: viewModel),
                currentUserName: authService.currentUser?.displayName,
                conversation: viewModel.currentConversation
            )
        }
    }
    
    @ViewBuilder
    private func messagesListView(viewModel: ChatViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(
                            message: message,
                            isCurrentUser: message.senderId == authService.currentUser?.id,
                            conversation: viewModel.currentConversation
                        )
                        .id(message.id)
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.deleteMessage(message)
                            } label: {
                                Label("Delete Message", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }
            .defaultScrollAnchor(.bottom)
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func typingIndicatorView(viewModel: ChatViewModel) -> some View {
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
    }
    
    @ViewBuilder
    private func networkStatusView() -> some View {
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
    }
    
    @ViewBuilder
    private func inputAreaView(viewModel: ChatViewModel) -> some View {
        VStack(spacing: 8) {
            pendingImagePreview(viewModel: viewModel)
            messageInputRow(viewModel: viewModel)
        }
    }
    
    @ViewBuilder
    private func pendingImagePreview(viewModel: ChatViewModel) -> some View {
        if let pendingData = viewModel.pendingImageData, let image = UIImage(data: pendingData) {
            HStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .topTrailing) {
                        Button(action: { viewModel.pendingImageData = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .offset(x: 8, y: -8)
                    }
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func messageInputRow(viewModel: ChatViewModel) -> some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selectedImage, matching: .images) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(viewModel.pendingImageData == nil ? .blue : .gray)
            }
            .disabled(viewModel.pendingImageData != nil)
            
            TextField("Message", text: Binding(
                get: { viewModel.messageText },
                set: { viewModel.messageText = $0 }
            ), axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .onChange(of: viewModel.messageText) { _, _ in
                    Task { @MainActor in
                        viewModel.handleTextChange()
                    }
                }
                .submitLabel(.send)
                .onSubmit {
                    if canSendMessage(for: viewModel) {
                        viewModel.sendMessage()
                    }
                }
            
            Button(action: {
                viewModel.sendMessage()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSendMessage(for: viewModel) ? .blue : .gray)
            }
            .disabled(!canSendMessage(for: viewModel))
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helpers
    
    private func participantNames(for viewModel: ChatViewModel) -> [String] {
        let currentUserId = authService.currentUser?.id ?? ""
        let others = viewModel.currentConversation.participantNames.filter { $0.key != currentUserId }
            .sorted { $0.value.lowercased() < $1.value.lowercased() }
            .map { $0.value }
        if let currentName = authService.currentUser?.displayName {
            return [currentName] + others
        }
        return others
    }
    
    private func otherParticipantId(for viewModel: ChatViewModel) -> String? {
        let currentUserId = authService.currentUser?.id ?? ""
        return viewModel.currentConversation.participants.first(where: { $0 != currentUserId })
    }
    
    private func canSendMessage(for viewModel: ChatViewModel) -> Bool {
        let trimmed = viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty || viewModel.pendingImageData != nil
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    let conversation: Conversation?  // Optional: Pass conversation for live avatar lookup
    @State private var showProfileDetail = false
    
    // Get the most up-to-date profile URL
    private var currentProfileUrl: String? {
        // If conversation is passed, use live profile URL (updated when user changes photo)
        if let conv = conversation {
            return conv.participantProfileUrls[message.senderId]
        }
        // Fallback to historical URL stored in message
        return message.senderProfileUrl
    }
    
    var body: some View {
        let hasText = !message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLocalImage = message.localImageData != nil
        let hasRemoteImage = (message.imageUrl ?? "").isEmpty == false
        let hasImage = hasLocalImage || hasRemoteImage
        
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser { Spacer() }
            
            // Avatar for received messages (on the left)
            if !isCurrentUser {
                Button {
                    showProfileDetail = true
                } label: {
                    UserAvatarView(
                        profilePictureUrl: currentProfileUrl,  // ← Uses live URL!
                        displayName: message.senderName,
                        size: 32
                    )
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showProfileDetail) {
                    UserProfileDetailView(userId: message.senderId)
                }
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser && message.senderName.isEmpty == false {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
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
                .padding(.horizontal, 4)
            }
            
            if !isCurrentUser { Spacer() }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .pending:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.orange)
        case .sending:
            ProgressView()
                .controlSize(.mini)
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
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(members, id: \.self) { name in
                        let userId = conversation.participantNames.first(where: { $0.value == name })?.key
                        let profileUrl = userId.flatMap { conversation.participantProfileUrls[$0] }
                        
                        HStack(spacing: 6) {
                            UserAvatarView(
                                profilePictureUrl: profileUrl,
                                displayName: name,
                                size: 26
                            )
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
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            case .empty:
                ProgressView()
                    .frame(width: 200, height: 200)
            case .failure:
                Color(.systemGray5)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            @unknown default:
                Color(.systemGray5)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

