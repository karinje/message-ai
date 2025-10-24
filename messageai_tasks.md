# Weftly - Task List & PR Breakdown

**App Name:** Weftly  
**Firebase Project:** Weftly  
**Bundle ID:** com.sanjaykarinje.weftly  

## MVP Status (Oct 24, 2025)
- ✅ Authentication & profiles (Firebase Email/Password, avatar support)
- ✅ 1:1 messaging with optimistic UI, read receipts, timestamps
- ✅ Group messaging (member roster header, real-time delivery)
- ✅ Image sharing with Firebase Storage + local caching (Nuke)
- ✅ Offline queue & auto-resend (tested via macOS Network Link Conditioner)
- ✅ **Typing indicators working** - fixed with conversation listener (PR #6)
- ✅ **Presence indicator working** - fixed with lifecycle handling (PR #6)
- ✅ Local in-app notifications mimicking push when app is active
- ✅ APNs push notifications working (FCM + APNs configured)
- ✅ 4-tab navigation (AI, Updates, Chats, Settings) with placeholders
- ✅ Manual QA on iOS simulators (iPhone 17 / iPhone 17 Pro)

## Enhanced Features Status (Phase 2)
- 🔜 Lists & Filters system (PR #13)
- 🔜 Privacy controls with reciprocal behavior (PR #13)
- 🔜 Broadcast messages (PR #14)
- 🔜 Contacts integration (PR #15)
- 🔜 Camera/photo quick access (PR #15)
- 🔜 Message search (PR #16)
- 🔜 Enhanced account management (PR #16)

## Project File Structure

```
Weftly/
├── Weftly.xcodeproj
├── Weftly/
│   ├── WeftlyApp.swift                       # App entry point
│   ├── GoogleService-Info.plist              # Firebase configuration
│   │
│   ├── Models/
│   │   ├── User.swift                        # User data model
│   │   ├── Message.swift                     # Message data model
│   │   ├── Conversation.swift                # Conversation/chat data model
│   │   └── MessageStatus.swift               # Enum for message states
│   │
│   ├── Services/
│   │   ├── FirebaseManager.swift             # Firebase initialization
│   │   ├── AuthService.swift                 # Authentication logic
│   │   ├── UserService.swift                 # User CRUD operations
│   │   ├── ChatService.swift                 # Messaging logic
│   │   ├── StorageService.swift              # Image upload/download
│   │   ├── NotificationService.swift         # Push notifications
│   │   └── NetworkMonitor.swift              # Network connectivity
│   │
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift               # Auth state management
│   │   ├── ChatListViewModel.swift           # Chat list logic
│   │   ├── ChatDetailViewModel.swift         # Message thread logic
│   │   ├── ProfileViewModel.swift            # User profile logic
│   │   └── GroupChatViewModel.swift          # Group chat logic
│   │
│   ├── Views/
│   │   ├── Auth/
│   │   │   ├── LoginView.swift               # Login screen
│   │   │   ├── SignUpView.swift              # Sign up screen
│   │   │   └── AuthContainerView.swift       # Auth flow container
│   │   │
│   │   ├── Main/
│   │   │   ├── ContentView.swift             # Root view with TabView
│   │   │   └── MainTabView.swift             # Tab navigation
│   │   │
│   │   ├── Chat/
│   │   │   ├── ChatListView.swift            # List of conversations
│   │   │   ├── ChatDetailView.swift          # Message thread
│   │   │   ├── MessageRow.swift              # Single message bubble
│   │   │   ├── MessageInputView.swift        # Text input field
│   │   │   ├── TypingIndicatorView.swift     # "User is typing..."
│   │   │   └── NewChatView.swift             # Start new conversation
│   │   │
│   │   ├── Group/
│   │   │   ├── CreateGroupView.swift         # Create group interface
│   │   │   ├── GroupDetailView.swift         # Group info screen
│   │   │   └── MemberSelectionView.swift     # Add members UI
│   │   │
│   │   ├── Profile/
│   │   │   ├── ProfileView.swift             # User profile screen
│   │   │   ├── EditProfileView.swift         # Edit profile
│   │   │   └── SettingsView.swift            # App settings
│   │   │
│   │   └── Components/
│   │       ├── UserAvatarView.swift          # Profile picture component
│   │       ├── OnlineStatusView.swift        # Online/offline indicator
│   │       ├── ImagePickerView.swift         # Image selection
│   │       └── LoadingView.swift             # Loading spinner
│   │
│   ├── Utilities/
│   │   ├── Extensions.swift                  # Swift extensions
│   │   ├── Constants.swift                   # App constants
│   │   ├── ImageCompressor.swift             # Image optimization
│   │   └── DateFormatter+Extensions.swift    # Time formatting
│   │
│   ├── Persistence/
│   │   ├── MessageAIDataModel.xcdatamodeld   # SwiftData schema
│   │   └── PersistenceController.swift       # SwiftData manager
│   │
│   └── Assets.xcassets/                      # Images, icons, colors
│
```

---

## PR Breakdown - MVP Phase (24 Hours)

### PR #1: Project Setup & Firebase Integration
**Branch:** `feature/project-setup`  
**Estimated Time:** 1-2 hours  
**Description:** Initialize Xcode project, add Firebase SDK, configure basic project structure

**Tasks:**
- [x] Create new iOS App project in Xcode (SwiftUI, Swift, iOS 17+)
- [x] Set bundle identifier: `com.sanjaykarinje.weftly`
- [x] Add Firebase SDK via Swift Package Manager
  - [x] Add package: `https://github.com/firebase/firebase-ios-sdk`
  - [x] Select: FirebaseAuth, FirebaseFirestore, FirebaseStorage, FirebaseMessaging
- [x] Create Firebase project at console.firebase.google.com
- [x] Add iOS app to Firebase (use bundle ID)
- [x] Download `GoogleService-Info.plist` and add to Xcode project
- [x] Create folder structure (Models, Services, Views, ViewModels, Utilities, Persistence)
- [x] Initialize Firebase in `weftlyApp.swift`
- [x] Test: App launches without errors

**Files Created/Modified (actual MVP):**
- `weftly/weftly/weftlyApp.swift`
- `GoogleService-Info.plist`
- Folder structure for Models/Services/ViewModels/Views/Utils

---

### PR #2: Authentication System
**Branch:** `feature/authentication`  
**Description:** Email/password auth with Firebase, session management

**Tasks (MVP implementation):**
- [x] Enable Firebase Authentication (Email/Password)
- [x] `User` model with id, email, displayName, profilePictureUrl, lastSeen, fcmToken
- [x] `AuthService` for sign up, login, logout, auth state listener
- [x] `LoginView` and `SignUpView` with validation & error handling
- [x] Auth state wiring in `ContentView`
- [x] Test manually: create account, logout, login again

*Unit/UI tests deferred for MVP.*

---

### PR #3: User Profile Management
**Branch:** `feature/user-profile`  
**Status:** Core profile CRUD implemented in MVP  
**Description:** User profiles stored in Firestore, profile picture support

**Tasks:**
- [x] Enable Cloud Firestore in Firebase Console (start in test mode)
- [x] Create `UserService.swift` for Firestore user CRUD operations
- [x] Create Firestore security rules (users can only edit their own profile)
- [x] Build `ProfileView.swift` to display current user info
- [x] Build `EditProfileView.swift` to update display name
- [x] Create `UserAvatarView.swift` component for profile pictures
- [x] Add placeholder avatar (SF Symbol "person.circle.fill")
- [x] Save user profile to Firestore on sign up
- [x] Verify: Update display name, check in Firestore Console

**Files Created:**
- `Services/UserService.swift`
- `ViewModels/ProfileViewModel.swift`
- `Views/Profile/ProfileView.swift`
- `Views/Profile/EditProfileView.swift`
- `Views/Components/UserAvatarView.swift`

**Files Modified:**
- `Services/AuthService.swift` (create user doc on signup)

---

### PR #4: Chat List & Navigation
**Branch:** `feature/chat-list`  
**Status:** ✅ Complete (chat list UI + 4-tab navigation)  
**Description:** Main navigation with 4-tab structure, chat list UI, conversation structure

**Reference Images:**
- `ref_imgs/settings_reference.png` - Settings tab (rightmost tab)
- `ref_imgs/chats_tab_with_list_filters_search_createbutton_camera_topright.png` - Chats tab (second from right)

**Tasks:**
- [x] Create `Conversation` model (id, participants, lastMessage, lastMessageTime, type)
- [x] Create `ChatService.swift` with method to fetch user's conversations
- [x] Create `ChatListViewModel.swift` to manage conversation list state
- [x] Build `MainTabView.swift` with 4 tabs (from right to left):
  - [x] **Tab 1 (rightmost):** Settings tab (basic placeholder, fully built in PR #13-16)
    - Contains: Account section, Lists, Broadcast Messages, Privacy
  - [x] **Tab 2 (second from right):** Chats tab (main chat list - build now)
    - Contains: All conversations, search, filters, + button for new chat/group
  - [x] **Tab 3 (third from right):** Updates tab (placeholder)
    - Contains: 24-hour status updates (future)
  - [x] **Tab 4 (leftmost):** AI tab (basic placeholder, fully built in PR #17-18)
    - Contains: AI assistant chat interface
- [x] Build `ChatListView.swift` with List of conversations
- [x] Create conversation row UI (avatar, name, last message preview, timestamp)
- [x] Build `NewChatView.swift` to start new conversation (select user)
- [x] Add "+ New Chat" button in navigation bar
- [x] Add real-time listener for conversation updates
- [x] Verify: Create conversation in Firestore manually, see it appear in list
- [x] Verify: All 4 tabs are visible and tappable in bottom tab bar

**Files Created:**
- `Models/Conversation.swift`
- `Services/ChatService.swift`
- `ViewModels/ChatListViewModel.swift`
- `Views/Main/MainTabView.swift`
- `Views/Chat/ChatListView.swift`
- `Views/Chat/NewChatView.swift`

**Files Modified:**
- `MessageAIApp.swift` (use MainTabView as root)

---

### PR #5: Core 1:1 Messaging
**Branch:** `feature/core-messaging`  
**Status:** Implemented end-to-end; persistence via SwiftData  
**Description:** Send/receive text messages, real-time sync, message persistence

**Tasks:**
- [x] Create `Message` model (id, text, senderId, timestamp, conversationId, status, readBy)
- [x] Create `MessageStatus` enum (sending, sent, delivered, read)
- [x] Add message CRUD methods to `ChatService.swift`
- [x] Implement Firestore structure: conversations/{id}/messages/{messageId}
- [x] Create `ChatDetailViewModel.swift` with message list and send logic
- [x] Build `ChatDetailView.swift` for message thread
- [x] Build `MessageRow.swift` for individual message bubbles (sender on right, receiver on left)
- [x] Build `MessageInputView.swift` with TextField and Send button
- [x] Implement optimistic UI (show message immediately with "sending" status)
- [x] Add real-time listener for new messages in conversation
- [x] Update conversation's lastMessage/lastMessageTime on send
- [x] Add SwiftData for local message persistence
- [x] Create `PersistenceController.swift` for SwiftData management
- [x] Save messages to SwiftData on receive
- [x] Load messages from SwiftData on app launch (offline support)
- [x] Verify: Send message from User A, appears on User B's device in real-time

**Files Created:**
- `Models/Message.swift`
- `Models/MessageStatus.swift`
- `ViewModels/ChatDetailViewModel.swift`
- `Views/Chat/ChatDetailView.swift`
- `Views/Chat/MessageRow.swift`
- `Views/Chat/MessageInputView.swift`
- `Persistence/MessageAIDataModel.xcdatamodeld`
- `Persistence/PersistenceController.swift`

**Files Modified:**
- `Services/ChatService.swift` (add message methods)

---

### PR #6: Real-Time Features (Typing, Presence)
**Branch:** `feature/realtime-indicators`  
**Status:** ✅ Complete (typing indicators + presence fixed)  
**Description:** Typing indicators and online/offline status

**FIXES IMPLEMENTED:**
- ✅ **Typing indicators working** - Added conversation document listener to detect typing changes in real-time
- ✅ **Presence indicator fixed** - Added app lifecycle handling + PresenceViewModel to check actual online status

**Tasks:**
- [x] Add `isTyping` field to conversations in Firestore
- [x] Add typing indicator logic to `ChatDetailViewModel.swift`
- [x] **FIXED:** Typing event sends correctly (debounced to 2 second timer)
- [x] **FIXED:** Added conversation document listener in ChatViewModel
- [x] Create `TypingIndicatorView.swift` component
- [x] Display typing indicator in `ChatDetailView.swift`
- [x] Add `lastSeen` timestamp to User model
- [x] **FIXED:** Added app lifecycle handling in weftlyApp.swift to update presence
- [x] **FIXED:** Created AuthService.updatePresence() method
- [x] Create `PresenceViewModel.swift` to check user online status
- [x] Display online status in chat list (green dot only when truly online)
- [x] **FIXED:** Online status checks both isOnline flag and lastSeen < 5 mins
- [x] Ready for testing on two devices

**Implementation Details:**
- Added `listenToConversation()` to FirestoreService for real-time typing updates
- ChatViewModel now listens to conversation document changes
- App lifecycle (active/background) updates user presence in Firestore
- PresenceViewModel listens to individual user documents for online status
- ConversationRow dynamically shows green dot based on actual online state

**Files Created:**
- `Views/Chat/TypingIndicatorView.swift`
- `Views/Components/OnlineStatusView.swift`

**Files Created:**
- `ViewModels/PresenceViewModel.swift`

**Files Modified:**
- `ViewModels/ChatViewModel.swift` (renamed from ChatDetailViewModel, added conversation listener)
- `Services/FirestoreService.swift` (added listenToConversation method)
- `Services/AuthService.swift` (added updatePresence method)
- `weftlyApp.swift` (added scene phase monitoring)
- `Views/Chat/ChatDetailView.swift` (use currentConversation for dynamic updates)
- `Views/Chat/ChatListView.swift` (ConversationRow uses PresenceViewModel)

---

### PR #7: Message Status & Read Receipts
**Branch:** `feature/message-status`  
**Status:** Implemented (status transitions + read receipts)  
**Description:** Delivery states, read receipts, checkmarks

**Tasks:**
- [x] Update message status to "sent" when Firestore confirms write
- [x] Add listener in `ChatService.swift` to update status to "delivered" when recipient receives
- [x] Implement read receipt logic: update `readBy` array when user opens chat
- [x] Mark all messages as read when ChatDetailView appears
- [x] Create checkmark icons (gray = sending, single = sent, double = delivered, blue double = read)
- [x] Display checkmarks in `MessageRow.swift` for sender's messages only
- [x] Add batch read update for efficiency
- [x] Verify: Send message, check status progression (sending → sent → delivered → read)

**Files Modified:**
- `Services/ChatService.swift` (read receipt logic)
- `ViewModels/ChatDetailViewModel.swift` (mark as read)
- `Views/Chat/MessageRow.swift` (display checkmarks)
- `Models/Message.swift` (ensure readBy array exists)

---

### PR #8: Group Chat
**Branch:** `feature/group-chat`  
**Status:** Implemented (group creation, roster header, delivery)  
**Description:** Create groups, multi-participant messaging

**Tasks:**
- [x] Update `Conversation` model to support group chat (add `name`, `isGroup`, `participants[]`)
- [x] Create `GroupChatViewModel.swift` for group logic
- [x] Build `CreateGroupView.swift` with name input and member selection
- [x] Build `MemberSelectionView.swift` to select multiple users
- [x] Build `GroupDetailView.swift` to view/edit group info
- [x] Update `ChatService.swift` to handle group message distribution
- [x] Update `MessageRow.swift` to show sender name/avatar in group chats
- [x] Add group icon to chat list (show member avatars or group icon)
- [x] Implement group-level read receipts (show count of who read)
- [x] Add "Create Group" option in NewChatView
- [x] Verify: Create group with 3 users, send messages, all users see messages

**Files Created:**
- `ViewModels/GroupChatViewModel.swift`
- `Views/Group/CreateGroupView.swift`
- `Views/Group/GroupDetailView.swift`
- `Views/Group/MemberSelectionView.swift`

**Files Modified:**
- `Models/Conversation.swift` (add group fields)
- `Services/ChatService.swift` (group message logic)
- `Views/Chat/MessageRow.swift` (show sender in groups)
- `Views/Chat/ChatListView.swift` (group icons)
- `Views/Chat/NewChatView.swift` (add group option)

---

### PR #9: Image Support
**Branch:** `feature/image-messaging`  
**Status:** Implemented (Firebase Storage + Nuke caching)  
**Description:** Send/receive images, Firebase Storage integration

**Tasks:**
- [x] Enable Firebase Cloud Storage in Firebase Console
- [x] Create `StorageService.swift` for image upload/download
- [x] Create `ImageCompressor.swift` utility (compress to max 1920px, JPEG 0.7 quality)
- [x] Create `ImagePickerView.swift` using PhotosUI
- [x] Add `mediaUrl` and `mediaType` fields to Message model
- [x] Update `MessageInputView.swift` to add image picker button
- [x] Implement image upload flow (compress → upload → send message with URL)
- [x] Show upload progress indicator
- [x] Update `MessageRow.swift` to display images using AsyncImage
- [x] Add tap-to-expand image functionality
- [x] Update SwiftData persistence to save image URLs
- [x] Verify: Send image, appears on recipient's device

**Files Created:**
- `Services/StorageService.swift`
- `Utilities/ImageCompressor.swift`
- `Views/Components/ImagePickerView.swift`

**Files Modified:**
- `Models/Message.swift` (add mediaUrl, mediaType)
- `Views/Chat/MessageInputView.swift` (image picker button)
- `ViewModels/ChatDetailViewModel.swift` (image send logic)
- `Views/Chat/MessageRow.swift` (display images)

---

### PR #10: Offline Support & Message Queue
**Branch:** `feature/offline-support`  
**Status:** Implemented (queue + retry tested via Network Link Conditioner)  
**Description:** Message queuing, network monitoring, offline resilience

**Tasks:**
- [x] Create `NetworkMonitor.swift` using NWPathMonitor
- [x] Add network status publisher to app
- [x] Implement message queue in SwiftData (pending messages table)
- [x] Save outgoing messages to queue with "pending" status
- [x] Add retry logic in `ChatService.swift` for failed sends
- [x] Implement background task to send queued messages when online
- [x] Handle app lifecycle (foreground/background) in `MessageAIApp.swift`
- [x] Add network error handling and user feedback
- [x] Implement idempotent sends (use message ID as Firestore doc ID)
- [x] Verify offline scenarios:
  - [x] Send message while offline → go online → message sends
  - [x] Force quit mid-send → reopen app → message sends
  - [x] Airplane mode → send 5 messages → disable airplane mode → all send

**Files Created:**
- `Services/NetworkMonitor.swift`

**Files Modified:**
- `Persistence/PersistenceController.swift` (add pending messages queue)
- `Services/ChatService.swift` (queue and retry logic)
- `ViewModels/ChatDetailViewModel.swift` (check network status)
- `MessageAIApp.swift` (app lifecycle handling)

---

### PR #11: Push Notifications
**Branch:** `feature/push-notifications`  
**Status:** ✅ Implemented end-to-end (APNs + FCM)  
**Description:** Firebase Cloud Messaging, foreground notifications

**Tasks:**
- [x] Enable Firebase Cloud Messaging in Firebase Console
- [x] Create `NotificationService.swift` for FCM setup
- [x] Request notification permissions on app launch
- [x] Register device token with Firebase
- [x] Store FCM token in user's Firestore document
- [x] Implement foreground notification handler (suppresses banner when active thread is open)
- [x] Display notification banner when app is active for other conversations
- [x] Add notification badge to app icon
- [x] Create Firebase Cloud Function to send notifications on new message
- [ ] Handle notification tap to open specific chat *(pending deep link wiring)*
- [x] Test: Send message while app is active/in background → appropriate notification behavior

**Files Created:**
- `Services/NotificationService.swift`
- `functions/index.js`
- `functions/package.json`
- `.firebaserc`
- `firebase.json`

**Files Modified:**
- `MessageAIApp.swift` (register for notifications)
- `Models/User.swift` (add fcmToken field)
- `Services/UserService.swift` *(deprecated in favor of AuthService token updates)*
- `Services/AuthService.swift` (refresh token on auth changes)
- `Services/NotificationService.swift` (APNs registration, active conversation tracking)
- `ViewModels/ChatListViewModel.swift` (feeds active conversation ID)
- `NotificationDelegate.swift` (foreground filtering logic)

**Notes:**
- Cloud Function `onMessageCreated` sends multicast FCM pushes with `conversationId` payload.
- Foreground notifications are suppressed when user is already viewing the active thread; otherwise banners + sounds show.
- Simulator builds swap in a local presenter that fires `UNNotificationRequest` mirrors when new messages arrive (APNs still required for background/device testing).
- Remaining work: deep-link into the correct chat on tap.

---

### PR #12: Polish & Bug Fixes
**Branch:** `feature/mvp-polish`  
**Status:** Core polish completed (UI tweaks, error handling)  
**Description:** UI polish, error handling, bug fixes

**Tasks:**
- [x] Add loading states to all views
- [x] Create `LoadingView.swift` component
- [x] Improve error messages (user-friendly text)
- [x] Add empty states (no conversations, no messages)
- [x] Polish message bubble design (colors, spacing, shadows)
- [x] Add haptic feedback for send button
- [x] Improve timestamp formatting (`DateFormatter+Extensions.swift`)
- [x] Add pull-to-refresh on chat list
- [x] Optimize Firestore queries (add indexes if needed)
- [x] Verify all MVP requirements:
  - [x] Real-time messaging between 2 devices
  - [x] Message persistence after restart
  - [x] Optimistic UI updates
  - [x] Offline → online transition
  - [x] Group chat with 3+ users
  - [x] Read receipts
  - [x] Image sending
  - [x] App force quit recovery
  - [x] Push notifications
  - [x] Online/offline status
- [x] Fix any bugs discovered
- [x] Prepare demo video script

**Files Created:**
- `Views/Components/LoadingView.swift`
- `Utilities/DateFormatter+Extensions.swift`

**Files Modified:**
- All View files (add loading/error states)
- `Utilities/Extensions.swift` (add helpers)

---

## Enhanced Features Phase (Days 8-10)

### PR #13: Lists & Filters + Privacy Controls
**Branch:** `feature/lists-and-privacy`  
**Estimated Time:** 6-8 hours  
**Description:** Build out Settings tab with Lists, Privacy, and Account sections (tab placeholder created in PR #4)

**Reference Images:**
- `ref_imgs/lists_creation_interface.png` - Lists creation UI with "Create a custom list" button
- `ref_imgs/settings_reference.png` - Settings tab layout showing Lists and Privacy sections
- `ref_imgs/chats_tab_with_list_filters_search_createbutton_camera_topright.png` - Filter chips on Chats tab

**Tasks - Lists & Filters:**
- [ ] Create `ConversationList` model (id, name, conversationIds, icon, isPreset)
- [ ] Create `ListsViewModel.swift` for list management
- [ ] Build `ListsView.swift` (main lists screen in Settings)
  - [ ] Top card with text: "Any list you create becomes a filter at the top of your Chats tab."
  - [ ] "+ Create a custom list" button (green, full width)
  - [ ] "Your lists" section showing active lists
  - [ ] "Available presets" section
- [ ] Build `CreateListView.swift` modal
  - [ ] Name input field
  - [ ] Icon picker (SF Symbols)
  - [ ] Conversation selection (checklist)
- [ ] Create preset lists in Firestore on user signup:
  - [ ] Unread (filter: conversations with unread count > 0)
  - [ ] Favorites (filter: conversations user has favorited)
  - [ ] Groups (filter: conversations where type = "group")
- [ ] Add list filter chips to ChatListView
  - [ ] Horizontal ScrollView above conversation list
  - [ ] Active chip highlighted with green background
  - [ ] Filter conversation list based on selected chip
- [ ] Implement list CRUD operations:
  - [ ] Create custom list
  - [ ] Add/remove conversations from list
  - [ ] Delete custom list (presets can't be deleted)
  - [ ] Reorder lists (drag to reorder in Your Lists section)
- [ ] Add "Add to List" action to conversation long-press menu
- [ ] Sync lists to Firestore: `users/{userId}/lists/{listId}`

**Tasks - Privacy Controls:**
- [ ] Add `PrivacySettings` model (lastSeenEnabled, readReceiptsEnabled)
- [ ] Create `PrivacyViewModel.swift` for privacy state
- [ ] Build `PrivacyView.swift` (accessed from Settings)
  - [ ] "Last seen and online" toggle
  - [ ] Subtitle explaining reciprocal behavior
  - [ ] "Read receipts" toggle
  - [ ] Subtitle explaining reciprocal behavior
  - [ ] Note: "Read receipts are always sent for group chats"
- [ ] Update `User` model to include `privacySettings` field
- [ ] Modify presence update logic:
  - [ ] Check recipient's `privacySettings.lastSeenEnabled` before showing status
  - [ ] If disabled, show user as offline (gray dot)
  - [ ] User with disabled setting also can't see others' status
- [ ] Modify read receipt logic:
  - [ ] Check both users' `readReceiptsEnabled` setting
  - [ ] Only send read receipt if both have it enabled
  - [ ] Group chats always send read receipts (bypass setting)
- [ ] Add privacy settings to Settings tab navigation
- [ ] Update Firestore security rules for privacy settings

**Files Created:**
- `Models/ConversationList.swift`
- `ViewModels/ListsViewModel.swift`
- `Views/Settings/ListsView.swift`
- `Views/Settings/CreateListView.swift`
- `ViewModels/PrivacyViewModel.swift`
- `Views/Settings/PrivacyView.swift`
- `Models/PrivacySettings.swift` (or extend User model)

**Files Modified:**
- `Models/User.swift` (add privacySettings field)
- `Views/Chat/ChatListView.swift` (add filter chips, list filtering)
- `Views/Settings/SettingsView.swift` (add Lists and Privacy sections)
- `Services/UserService.swift` (presence logic respects privacy)
- `Services/ChatService.swift` (read receipts respect privacy)

**Verification Checklist:**
- [ ] Create custom list → appears in ChatListView as filter chip
- [ ] Add conversation to list → appears when filter active
- [ ] Toggle "Last seen" OFF → user appears offline to others
- [ ] Toggle "Read receipts" OFF → blue checkmarks not sent
- [ ] Verify reciprocal: Can't see others' status when own is disabled
- [ ] Group chat → read receipts always work regardless of setting

---

### PR #14: Broadcast Messages
**Branch:** `feature/broadcast-messages`  
**Estimated Time:** 4-5 hours  
**Description:** Send same message to multiple contacts without group chat

**Reference Images:**
- `ref_imgs/new_list_button_on_broadcasts.png` - Broadcast screen with "New List" button and empty state text

**Tasks:**
- [ ] Create `BroadcastList` model (id, name, recipientIds, lastUsed, messageCount)
- [ ] Create `BroadcastViewModel.swift` for broadcast management
- [ ] Build `BroadcastView.swift` (accessed from Settings)
  - [ ] Empty state: "You should use broadcast lists to message multiple people at once"
  - [ ] "New List" button at bottom (green, full width)
  - [ ] List of created broadcast lists
- [ ] Build `CreateBroadcastListView.swift`
  - [ ] Recipient selection screen (similar to group creation)
  - [ ] Search bar at top
  - [ ] Alphabetical contact list with checkboxes
  - [ ] Selected count: "0/256" at top
  - [ ] "Create" button when at least 1 recipient selected
- [ ] Build `BroadcastListDetailView.swift`
  - [ ] List name (editable)
  - [ ] Recipient list with avatars
  - [ ] "Edit Recipients" button
  - [ ] "Send Message" button
- [ ] Implement broadcast send logic:
  - [ ] When user sends message to broadcast list
  - [ ] Create/update individual 1:1 conversations with each recipient
  - [ ] Send same message to each conversation
  - [ ] Track delivery status per recipient
- [ ] Build `BroadcastComposeView.swift` or reuse ChatDetailView
  - [ ] Message input field
  - [ ] Send button
  - [ ] Delivery status for each recipient
- [ ] Sync broadcast lists to Firestore: `users/{userId}/broadcastLists/{listId}`
- [ ] Add "New broadcast" option in New Chat modal (+)

**Files Created:**
- `Models/BroadcastList.swift`
- `ViewModels/BroadcastViewModel.swift`
- `Views/Broadcast/BroadcastView.swift`
- `Views/Broadcast/CreateBroadcastListView.swift`
- `Views/Broadcast/BroadcastListDetailView.swift`

**Files Modified:**
- `Views/Settings/SettingsView.swift` (add Broadcast Messages section)
- `Views/Chat/NewChatView.swift` (add New broadcast option)
- `Services/ChatService.swift` (broadcast send logic)

**Verification Checklist:**
- [ ] Create broadcast list with 5 recipients
- [ ] Send message → 5 separate 1:1 conversations created
- [ ] Verify messages sent individually (not as group)
- [ ] Edit broadcast list → add/remove recipients
- [ ] Verify delivery status shows for each recipient

---

### PR #15: Contacts Integration + Camera Quick Access
**Branch:** `feature/contacts-and-camera`  
**Estimated Time:** 5-6 hours  
**Description:** Import phone contacts, quick camera/photo access

**Reference Images:**
- `ref_imgs/hitting_plus_on_chats.png` - New Chat modal showing "New group", "New contact", frequently contacted, and all contacts sections
- `ref_imgs/chats_tab_with_list_filters_search_createbutton_camera_topright.png` - Chats tab with camera button (top right)

**Tasks - Contacts Integration:**
- [ ] Create `ContactsService.swift` using Contacts framework
- [ ] Request contacts permission on first app launch or first "New Chat" tap
- [ ] Implement contact sync flow:
  - [ ] Extract phone numbers from device contacts
  - [ ] Normalize to E.164 format (+1XXXXXXXXXX)
  - [ ] Hash phone numbers (SHA-256) for privacy
  - [ ] Upload hashes to Firestore for matching
- [ ] Query Firestore to find users with matching phone number hashes
- [ ] Update `User` model:
  - [ ] Add `phoneNumberHash` field
  - [ ] Add `contactsSynced: boolean`
  - [ ] Add `contactSyncTimestamp: timestamp`
- [ ] Update NewChatView to show contacts sections:
  - [ ] "Frequently contacted" (top 3-5 by message count)
  - [ ] "Contacts on Weftly" (alphabetical with section headers)
  - [ ] "Invite to Weftly" (contacts not on app)
- [ ] Add contact sync status indicator
- [ ] Add manual "Refresh Contacts" option in Settings
- [ ] Handle permission denied: show manual "Add Contact" option

**Tasks - Camera Quick Access:**
- [ ] Add camera icon button to ChatListView navigation bar (top right)
- [ ] Implement bottom sheet on camera icon tap:
  - [ ] "Take Photo" option (camera icon)
  - [ ] "Choose from Library" option (photo icon)
- [ ] Request camera permission on first "Take Photo" tap
- [ ] Request photo library permission on first "Choose from Library" tap
- [ ] After photo selection:
  - [ ] Show contact selection screen
  - [ ] User selects recipient
  - [ ] Navigate to chat with photo attached to input field
  - [ ] Ready to send (user can add caption or send)
- [ ] Handle permission denied: show settings alert

**Files Created:**
- `Services/ContactsService.swift`
- `ViewModels/ContactsViewModel.swift`
- `Views/Components/CameraAccessSheet.swift`
- `Views/Components/ContactPermissionView.swift`

**Files Modified:**
- `Models/User.swift` (add phoneNumberHash, contactsSynced fields)
- `Views/Chat/NewChatView.swift` (add contacts sections)
- `Views/Chat/ChatListView.swift` (add camera button)
- `Services/AuthService.swift` (sync contacts on signup)

**Verification Checklist:**
- [ ] First launch → contacts permission prompt appears
- [ ] Grant permission → contacts sync in background
- [ ] New Chat → see "Contacts on Weftly" populated
- [ ] Verify only users with matching phone numbers appear
- [ ] Tap camera icon → bottom sheet appears
- [ ] Take photo → select recipient → photo attached to chat
- [ ] Choose from library → select photo → recipient → attached

---

### PR #16: Search + Enhanced Account Management
**Branch:** `feature/search-and-account`  
**Estimated Time:** 4-5 hours  
**Description:** Message search, complete Settings tab Account section with profile picture upload, About field, and account actions

**Reference Images:**
- `ref_imgs/profile_page.png` - Profile view with avatar, Edit button, Name, About, and Phone number fields
- `ref_imgs/settings_reference.png` - Settings tab showing Account section and action buttons
- `ref_imgs/chats_tab_with_list_filters_search_createbutton_camera_topright.png` - Search bar on Chats tab

**Tasks - Message Search:**
- [ ] Add search bar to ChatListView (below navigation bar)
- [ ] Implement search logic:
  - [ ] Search conversation names (real-time filter)
  - [ ] Filter conversation list as user types
  - [ ] Clear button (X) to reset search
- [ ] **Option A (MVP):** Basic Firestore search
  - [ ] Query conversations where displayName contains search term
  - [ ] Case-insensitive substring matching
- [ ] **Future:** Add Algolia integration for full-text message search
  - [ ] Document structure for future reference
  - [ ] Notes on implementation approach

**Tasks - Enhanced Account Management:**
- [ ] Update ProfileView with proper layout:
  - [ ] Large circular avatar (200pt diameter, centered)
  - [ ] "Edit" button below avatar
  - [ ] Name field (tappable to edit)
  - [ ] About field (tappable to edit, max 139 chars)
  - [ ] Phone number field (display only, formatted)
- [ ] Implement profile picture upload:
  - [ ] Tap "Edit" → PhotosPicker appears
  - [ ] Select photo → compress (max 1920px, JPEG 0.7)
  - [ ] Upload to Firebase Storage
  - [ ] Update user document with profilePictureUrl
  - [ ] Show loading indicator during upload
- [ ] Add About field editing:
  - [ ] Tap field → sheet with TextField
  - [ ] Max 139 characters
  - [ ] Save to Firestore
- [ ] Add Settings navigation from Settings tab
- [ ] Add account actions to SettingsView (bottom):
  - [ ] **Sign Out** button
    - [ ] Confirmation alert: "Are you sure?"
    - [ ] Clear local auth token
    - [ ] Remove FCM token from Firestore
    - [ ] Return to login screen
  - [ ] **Delete All Chats** button (destructive)
    - [ ] Alert: "This will delete all your chat history. This cannot be undone."
    - [ ] Delete all messages from SwiftData
    - [ ] Option to delete from Firestore too
  - [ ] **Delete Account** button (most destructive)
    - [ ] First alert: "Delete account? All your data will be permanently removed."
    - [ ] Second alert: "Are you absolutely sure? This cannot be undone."
    - [ ] Delete user document from Firestore
    - [ ] Delete all user's messages from conversations
    - [ ] Remove profile picture from Storage
    - [ ] Delete Firebase Auth account
    - [ ] Return to signup screen

**Files Created:**
- `Views/Settings/EditAboutView.swift`
- `Views/Settings/AccountActionsView.swift`

**Files Modified:**
- `Views/Chat/ChatListView.swift` (add search bar)
- `Views/Profile/ProfileView.swift` (enhanced layout)
- `Views/Settings/SettingsView.swift` (add account actions)
- `Services/AuthService.swift` (sign out, delete account logic)
- `Services/UserService.swift` (profile picture upload)

**Verification Checklist:**
- [ ] Search bar filters conversations by name in real-time
- [ ] Upload profile picture → appears in profile and chat list
- [ ] Edit About field → updates in Firestore
- [ ] Sign out → returns to login, clears auth
- [ ] Delete All Chats → local messages deleted
- [ ] Delete Account → full cleanup, account removed

---

## Post-MVP: AI Features Phase (Days 11-14)

### PR #17: AI Infrastructure Setup
**Branch:** `feature/ai-infrastructure`  
**Estimated Time:** 2-3 hours  
**Description:** Firebase Cloud Functions, OpenAI/Claude API integration

**Tasks:**
- [ ] Initialize Firebase Cloud Functions project
- [ ] Install AI SDK dependencies (OpenAI or Anthropic)
- [ ] Create Cloud Function for AI chat endpoint
- [ ] Implement secure API key storage (Firebase environment config)
- [ ] Create `AIService.swift` in iOS app to call Cloud Functions
- [ ] Add conversation history retrieval (RAG pipeline basics)
- [ ] Verify: Call AI function from app, get response

**Files Created:**
- `functions/index.js` (Cloud Functions)
- `functions/package.json`
- `Services/AIService.swift`
- `ViewModels/AIViewModel.swift`

---

### PR #18: AI Chat Interface
**Branch:** `feature/ai-chat-interface`  
**Estimated Time:** 3-4 hours  
**Description:** Build out AI tab with dedicated AI assistant chat interface (tab placeholder created in PR #4)

**Tasks:**
- [ ] Create AI conversation type in Firestore
- [ ] Build `AIChatView.swift` for AI assistant interface
- [ ] Connect AI tab in MainTabView to AIChatView (replace placeholder)
- [ ] Implement streaming responses (if supported)
- [ ] Add context: let AI access user's message history
- [ ] Create AI avatar/branding
- [ ] Verify: Ask AI a question about conversations

**Files Created:**
- `Views/AI/AIChatView.swift`
- `ViewModels/AIChatViewModel.swift`

**Files Modified:**
- `Views/Main/MainTabView.swift` (add AI tab)

---

### PR #19: Required AI Feature #1 - Smart Calendar Extraction
**Branch:** `feature/ai-calendar-extraction`  
**Estimated Time:** 4-5 hours  
**Description:** Detect dates/times/events in messages

**Tasks:**
- [ ] Create Cloud Function for calendar extraction using LLM
- [ ] Implement prompt engineering for date/time parsing
- [ ] Add function calling for structured output (date, time, event)
- [ ] Create UI indicator for detected events (chip/badge on message)
- [ ] Build calendar export functionality (iCal format)
- [ ] Add "Add to Calendar" button on detected events
- [ ] Verify with various date formats ("next Tuesday", "12/25", "tomorrow at 3pm")

**Files Created:**
- `functions/calendarExtractor.js`
- `Views/Components/EventChipView.swift`

**Files Modified:**
- `Services/AIService.swift` (calendar extraction endpoint)
- `Views/Chat/MessageRow.swift` (show event chips)

---

### PR #20: Required AI Feature #2 - Decision Summarization
**Branch:** `feature/ai-decision-summary`  
**Estimated Time:** 4-5 hours  
**Description:** Summarize decisions from group chats

**Tasks:**
- [ ] Create Cloud Function for decision summarization
- [ ] Implement RAG: retrieve last N messages from conversation
- [ ] Engineer prompt to identify decisions/conclusions
- [ ] Build `DecisionSummaryView.swift` sheet
- [ ] Add "Summarize Decisions" button in group chat toolbar
- [ ] Display summary with timestamps and participants
- [ ] Cache summaries to reduce API costs
- [ ] Verify on long group chat threads (50+ messages)

**Files Created:**
- `functions/decisionSummarizer.js`
- `Views/AI/DecisionSummaryView.swift`

**Files Modified:**
- `Services/AIService.swift` (summary endpoint)
- `Views/Chat/ChatDetailView.swift` (summary button)

---

### PR #21: Required AI Feature #3 - Priority Message Highlighting
**Branch:** `feature/ai-priority-detection`  
**Estimated Time:** 4-5 hours  
**Description:** Auto-detect urgent/important messages

**Tasks:**
- [ ] Create Cloud Function for priority detection
- [ ] Implement sentiment + urgency analysis with LLM
- [ ] Define priority levels (urgent, important, normal)
- [ ] Add `priority` field to Message model
- [ ] Run priority detection on incoming messages (background)
- [ ] Update `MessageRow.swift` to highlight urgent messages (red border/icon)
- [ ] Add filter in ChatListView to show priority messages
- [ ] Verify with urgent keywords ("emergency", "ASAP", "school closed")

**Files Created:**
- `functions/priorityDetector.js`

**Files Modified:**
- `Models/Message.swift` (add priority field)
- `Services/AIService.swift` (priority detection endpoint)
- `Views/Chat/MessageRow.swift` (priority styling)
- `Views/Chat/ChatListView.swift` (priority filter)

---

### PR #22: Required AI Feature #4 - RSVP Tracking
**Branch:** `feature/ai-rsvp-tracking`  
**Estimated Time:** 4-5 hours  
**Description:** Track event confirmations in group chats

**Tasks:**
- [ ] Create Cloud Function to detect RSVP requests
- [ ] Identify invitation messages (LLM pattern matching)
- [ ] Parse responses ("I can come", "count me in", "can't make it")
- [ ] Create RSVP data structure (event, yesCount, noCount, maybeCount)
- [ ] Build `RSVPTrackerView.swift` to display headcount
- [ ] Show RSVP summary below invitation message
- [ ] Add manual RSVP buttons (Yes/No/Maybe)
- [ ] Verify with various invitation formats

**Files Created:**
- `functions/rsvpTracker.js`
- `Views/AI/RSVPTrackerView.swift`
- `Models/RSVPEvent.swift`

**Files Modified:**
- `Services/AIService.swift` (RSVP endpoints)
- `Views/Chat/MessageRow.swift` (RSVP UI)

---

### PR #23: Required AI Feature #5 - Deadline/Reminder Extraction
**Branch:** `feature/ai-deadline-extraction`  
**Estimated Time:** 4-5 hours  
**Description:** Auto-detect deadlines and set reminders

**Tasks:**
- [ ] Create Cloud Function for deadline detection
- [ ] Identify deadline patterns ("due Friday", "by end of week", "permission slip deadline")
- [ ] Extract: task, deadline date/time, context
- [ ] Create reminder system (local notifications)
- [ ] Build `DeadlineListView.swift` to show all upcoming deadlines
- [ ] Add reminder notification 24 hours before deadline
- [ ] Allow users to snooze/dismiss reminders
- [ ] Verify with various deadline formats

**Files Created:**
- `functions/deadlineExtractor.js`
- `Views/AI/DeadlineListView.swift`
- `Models/Deadline.swift`

**Files Modified:**
- `Services/AIService.swift` (deadline endpoint)
- `Services/NotificationService.swift` (reminder notifications)

---

### PR #24: Advanced AI Feature - Proactive Assistant
**Branch:** `feature/ai-proactive-assistant`  
**Estimated Time:** 6-8 hours  
**Description:** Detect conflicts, suggest solutions

**Tasks:**
- [ ] Integrate with user's calendar (EventKit)
- [ ] Create conflict detection Cloud Function
- [ ] Analyze new messages against calendar events
- [ ] Detect scheduling conflicts ("Can you pick up at 3?" when meeting at 3)
- [ ] Build proactive notification system
- [ ] Generate suggested responses ("I have a meeting, can we do 4pm instead?")
- [ ] Build `ConflictAlertView.swift` sheet
- [ ] Add AI suggestion chips in message compose
- [ ] Verify conflict scenarios with live data

**Files Created:**
- `functions/proactiveAssistant.js`
- `Views/AI/ConflictAlertView.swift`
- `Services/CalendarService.swift`

**Files Modified:**
- `ViewModels/ChatDetailViewModel.swift` (conflict detection)
- `Views/Chat/MessageInputView.swift` (suggestion chips)

---

## Git Workflow

### Branch Naming Convention
- Feature: `feature/feature-name`
- Bug fix: `fix/bug-description`
- Hotfix: `hotfix/issue-description`

### Commit Message Format
```
[PR #X] Brief description

- Detailed change 1
- Detailed change 2
- Files modified: File1.swift, File2.swift
```

### PR Checklist (before merging)
- [ ] Code compiles without errors
- [ ] All new features verified on device/simulator
- [ ] No console errors or warnings
- [ ] Code follows Swift style guide
- [ ] Comments added for complex logic
- [ ] PR description includes screenshots/demo if UI changes

---

## Progress Tracking

Track your progress by checking off PRs as you complete them:

**MVP Phase (Completed)** ✅
- [x] PR #1: Project Setup ✅
- [x] PR #2: Authentication ✅
- [x] PR #3: User Profile ✅
- [x] PR #4: Chat List & 4-Tab Navigation ✅
- [x] PR #5: Core Messaging ✅
- [x] PR #6: Real-Time Features ✅ **FIXED** (typing indicators + presence working)
- [x] PR #7: Message Status ✅
- [x] PR #8: Group Chat ✅
- [x] PR #9: Image Support ✅
- [x] PR #10: Offline Support ✅
- [x] PR #11: Push Notifications ✅
- [x] PR #12: Polish & Bug Fixes ✅

**Enhanced Features Phase (Days 8-10)** *(In Progress)*
- [ ] PR #13: Lists & Filters + Privacy Controls
- [ ] PR #14: Broadcast Messages
- [ ] PR #15: Contacts Integration + Camera Quick Access
- [ ] PR #16: Search + Enhanced Account Management

**AI Features Phase (Days 11-14)** *(Not started)*
- [ ] PR #17: AI Infrastructure
- [ ] PR #18: AI Chat Interface
- [ ] PR #19: Calendar Extraction
- [ ] PR #20: Decision Summarization
- [ ] PR #21: Priority Detection
- [ ] PR #22: RSVP Tracking
- [ ] PR #23: Deadline Extraction
- [ ] PR #24: Proactive Assistant

**Final Deliverables**
- [ ] Demo video recorded
- [ ] Persona Brainlift document written
- [ ] TestFlight build uploaded
- [ ] Social post published

---

## Next Steps

### Immediate Priorities (Oct 24, 2025)

**1. ✅ MVP Complete!**
- All 12 PRs implemented
- Typing indicators + presence working
- 4-tab navigation in place
- Ready for enhanced features

**2. Begin Enhanced Features Phase:**
- Start PR #13: Lists & Filters + Privacy Controls
- Implement custom conversation lists
- Add WhatsApp-style privacy toggles

**3. Continue Building:**
- PR #14: Broadcast Messages
- PR #15: Contacts Integration + Camera Access
- PR #16: Search + Account Management

**Development Best Practices:**
1. **Commit Early, Commit Often:** Push code after each subtask
2. **Verify Between PRs:** Don't let bugs accumulate
3. **Use Two Devices:** Verify real-time features on multiple devices
4. **Check Firestore Console:** Verify data structure and updates
5. **Add Debug Logs:** Console.log to track typing events and presence updates

**Timeline:**
- Days 8-10: Enhanced Features (PR #13-16)
- Days 11-14: AI Features (PR #17-24)
- Day 15: Final polish, demo video, deliverables