//
//  ChatListView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI
import SwiftData

struct ChatListView: View {
    @StateObject private var viewModel: ChatListViewModel
    @StateObject private var listsViewModel: ListsViewModel
    @StateObject private var broadcastViewModel: BroadcastViewModel
    @ObservedObject var authService: AuthService
    @ObservedObject var networkMonitor: NetworkMonitor
    @Environment(\.modelContext) private var modelContext
    @State private var showNewChat = false
    @State private var showSearch = false
    @State private var showBroadcast = false
    @State private var showCameraSheet = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var searchText = ""
    @State private var selectedList: ConversationList?
    
    init(authService: AuthService, networkMonitor: NetworkMonitor) {
        self.authService = authService
        self.networkMonitor = networkMonitor
        _viewModel = StateObject(wrappedValue: ChatListViewModel(authService: authService))
        _listsViewModel = StateObject(wrappedValue: ListsViewModel(authService: authService))
        _broadcastViewModel = StateObject(wrappedValue: BroadcastViewModel(authService: authService))
    }
    
    var filteredConversations: [Conversation] {
        var conversations = viewModel.conversations
        
        print("🔍 Total conversations: \(conversations.count), Selected list: \(selectedList?.name ?? "nil (All)")")
        
        // Apply list filter
        if let list = selectedList, let currentUserId = authService.currentUser?.id {
            // Special handling for preset lists
            switch list.id {
            case "preset-unread":
                // Use local cache-based unread detection (100% local - KEY FIX)
                conversations = conversations.filter { conv in
                    guard let convId = conv.id else { return false }
                    do {
                        let unreadCount = try MessageCacheService.shared.calculateUnreadCount(
                            for: convId,
                            currentUserId: currentUserId,
                            in: modelContext
                        )
                        return unreadCount > 0
                    } catch {
                        print("❌ Error calculating unread count for filter: \(error)")
                        return false
                    }
                }
                print("🔍 After Unread filter (local cache): \(conversations.count)")
            case "preset-groups":
                conversations = conversations.filter { conv in
                    conv.type == .group
                }
                print("🔍 After Groups filter: \(conversations.count)")
            default:
                // Custom list - filter by conversationIds from Firestore
                conversations = conversations.filter { conv in
                    guard let convId = conv.id else { return false }
                    return list.conversationIds.contains(convId)
                }
                print("🔍 After custom list filter: \(conversations.count)")
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            conversations = conversations.filter { conversation in
                conversation.displayName(for: authService.currentUser?.id ?? "")
                    .localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return conversations
    }
    
    var allLists: [ConversationList] {
        // Only return custom lists from ViewModel
        return listsViewModel.customLists
    }
    
    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search", text: $searchText)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                FilterChip(
                    title: "All",
                    icon: nil,
                    isSelected: selectedList == nil
                ) {
                    selectedList = nil
                }
                
                // Preset filter chips
                FilterChip(
                    title: "Unread",
                    icon: "circle.fill",
                    isSelected: selectedList?.id == "preset-unread"
                ) {
                    selectedList = .unreadList
                }
                
                FilterChip(
                    title: "Groups",
                    icon: "person.3.fill",
                    isSelected: selectedList?.id == "preset-groups"
                ) {
                    selectedList = .groupsList
                }
                
                // Custom list filter chips
                ForEach(allLists) { list in
                    FilterChip(
                        title: list.name,
                        icon: list.icon,
                        isSelected: selectedList?.id == list.id
                    ) {
                        selectedList = list
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
    
    var conversationList: some View {
        List {
            ForEach(filteredConversations) { conversation in
                let unread = viewModel.getUnreadCount(for: conversation)
                conversationRow(for: conversation, unreadCount: unread)
            }
        }
        .listStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func conversationRow(for conversation: Conversation, unreadCount: Int) -> some View {
        let destination = ChatDetailView(
            conversation: conversation,
            authService: authService,
            chatListViewModel: viewModel,
            modelContext: modelContext
        )
        return NavigationLink(destination: destination) {
            ConversationRow(
                conversation: conversation,
                currentUserId: authService.currentUser?.id ?? "",
                unreadCount: unreadCount
            )
        }
        .contextMenu {
            contextMenuContent(for: conversation)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.deleteConversation(conversation)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    func contextMenuContent(for conversation: Conversation) -> some View {
        Group {
            if !listsViewModel.customLists.isEmpty {
                Menu("Add to List") {
                    ForEach(listsViewModel.customLists) { list in
                        Button {
                            if let listId = list.id, let convId = conversation.id {
                                Task {
                                    try? await listsViewModel.addConversationToList(listId: listId, conversationId: convId)
                                }
                            }
                        } label: {
                            Label(list.name, systemImage: list.icon ?? "list.bullet")
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                filterChips
                conversationList
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            Task {
                                try? await authService.signOut()
                            }
                        } label: {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Group {
                            if let user = authService.currentUser {
                                Text(user.displayName.prefix(2).uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 32, height: 32)
                            }
                        }
                        .id(authService.currentUser?.id ?? "loading")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 20) {
                        // Camera button
                        Button {
                            showCameraSheet = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.title3)
                        }
                        
                        // New chat menu button
                        Menu {
                            Button {
                                showSearch = true
                            } label: {
                                Label("New Direct Chat", systemImage: "person.badge.plus")
                            }
                            
                            Button {
                                showNewChat = true
                            } label: {
                                Label("New Group Chat", systemImage: "person.3.fill")
                            }
                            
                            Divider()
                            
                            Button {
                                showBroadcast = true
                            } label: {
                                Label("New Broadcast", systemImage: "megaphone")
                            }
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                UserSearchView(authService: authService, viewModel: viewModel, networkMonitor: networkMonitor)
            }
            .sheet(isPresented: $showNewChat) {
                NewGroupView(authService: authService, viewModel: viewModel, networkMonitor: networkMonitor)
            }
            .sheet(isPresented: $showBroadcast) {
                CreateBroadcastListView(viewModel: broadcastViewModel)
            }
            .confirmationDialog("Camera Options", isPresented: $showCameraSheet) {
                Button("Take Photo") {
                    showCamera = true
                }
                Button("Choose from Library") {
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView { image in
                    // Handle camera image - for now just show search to select recipient
                    showSearch = true
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImageLibraryPickerView { image in
                    // Handle library image - for now just show search to select recipient
                    showSearch = true
                }
            }
            .onAppear {
                print("📱 ChatListView appeared, user: \(authService.currentUser?.displayName ?? "nil")")
                
                // Wire up model context to viewModel (KEY for unread counter fix)
                viewModel.setModelContext(modelContext)
                
                if authService.currentUser != nil {
                    viewModel.startListening()
                    listsViewModel.startListening()
                }
            }
            .onDisappear {
                viewModel.stopListening()
                listsViewModel.stopListening()
            }
            .onChange(of: authService.currentUser) { _, newUser in
                print("📱 Auth state changed, user: \(newUser?.displayName ?? "nil")")
                viewModel.stopListening()
                if newUser != nil {
                    viewModel.startListening()
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: String
    let unreadCount: Int  // Passed from parent (100% local calculation - KEY FIX)
    @StateObject private var presenceViewModel: PresenceViewModel
    
    init(conversation: Conversation, currentUserId: String, unreadCount: Int) {
        self.conversation = conversation
        self.currentUserId = currentUserId
        self.unreadCount = unreadCount
        
        // For direct chats, get the other user's ID
        let otherUserId = conversation.type == .direct 
            ? conversation.participants.first(where: { $0 != currentUserId }) 
            : nil
        
        print("💬 ConversationRow init: convId=\(conversation.id ?? "nil"), participants=\(conversation.participants), current=\(currentUserId), other=\(otherUserId ?? "nil"), unread=\(unreadCount)")
        
        _presenceViewModel = StateObject(wrappedValue: PresenceViewModel(userId: otherUserId))
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(conversation.displayName(for: currentUserId).prefix(2).uppercased())
                            .font(.headline)
                            .foregroundStyle(.blue)
                    )
                
                // Online indicator for direct chats
                if conversation.type == .direct && presenceViewModel.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayName(for: currentUserId))
                        .font(.headline)
                        .fontWeight(unreadCount > 0 ? .semibold : .regular)
                    
                    Spacer()
                    
                    if let lastMessageTime = conversation.lastMessageTime {
                        Text(lastMessageTime.timeAgoDisplay())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage)
                            .font(.subheadline)
                            .foregroundStyle(unreadCount > 0 ? .primary : .secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Unread count badge (WhatsApp style) using local cache
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, unreadCount > 9 ? 6 : 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

