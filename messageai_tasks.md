# Weftly - Task List & PR Breakdown

**App Name:** Weftly  
**Firebase Project:** Weftly  
**Bundle ID:** com.sanjaykarinje.weftly  

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
├── MessageAITests/                           # Unit tests
└── MessageAIUITests/                         # UI tests
```

---

## Testing Strategy Overview

**11 PRs with Required Tests** (ensuring AI-generated code correctness)

### MVP Phase Tests (6 PRs)
- ✅ **PR #2:** Unit Tests + Integration Test (Authentication flow)
- ✅ **PR #3:** Unit Tests (User CRUD operations)
- ✅ **PR #5:** Unit Tests + Integration Test (Core messaging - CRITICAL)
- ✅ **PR #7:** Unit Tests (Message status transitions)
- ✅ **PR #8:** Unit Tests + Integration Test (Group chat distribution)
- ✅ **PR #9:** Unit Tests (Image compression & upload)
- ✅ **PR #10:** Unit Tests + Integration Test (Offline queue - CRITICAL)

### AI Phase Tests (5 PRs)
- ✅ **PR #13:** Unit Tests (AI infrastructure & API calls)
- ✅ **PR #15:** Unit Tests (Calendar extraction accuracy)
- ✅ **PR #17:** Unit Tests (Priority detection accuracy)
- ✅ **PR #18:** Unit Tests (RSVP parsing & aggregation)
- ✅ **PR #19:** Unit Tests (Deadline extraction)
- ✅ **PR #20:** Unit Tests + Integration Test (Proactive assistant - ADVANCED)

### Why These PRs?
**Critical Business Logic:** PRs with complex logic (messaging, offline sync, auth) require tests to catch edge cases AI agents might miss.

**Data Accuracy:** AI features (calendar, RSVP, deadlines) need tests to validate extraction accuracy and prevent false positives.

**Integration Points:** Multi-component features (messaging flow, group chat, offline sync) benefit from end-to-end tests.

**Skipped PRs:** UI-only PRs (#1, #4, #6, #11, #12, #14, #16) don't require tests as they're primarily visual and easy to verify manually.

---

## PR Breakdown - MVP Phase (24 Hours)

### PR #1: Project Setup & Firebase Integration
**Branch:** `feature/project-setup`  
**Estimated Time:** 1-2 hours  
**Description:** Initialize Xcode project, add Firebase SDK, configure basic project structure

**Tasks:**
- [ ] Create new iOS App project in Xcode (SwiftUI, Swift, iOS 17+)
- [ ] Set bundle identifier: `com.[yourname].messageai`
- [ ] Add Firebase SDK via Swift Package Manager
  - Add package: `https://github.com/firebase/firebase-ios-sdk`
  - Select: FirebaseAuth, FirebaseFirestore, FirebaseStorage, FirebaseMessaging
- [ ] Create Firebase project at console.firebase.google.com
- [ ] Add iOS app to Firebase (use bundle ID)
- [ ] Download `GoogleService-Info.plist` and add to Xcode project
- [ ] Create folder structure (Models, Services, Views, ViewModels, Utilities, Persistence)
- [ ] Initialize Firebase in `MessageAIApp.swift`
- [ ] Test: App launches without errors

**Files Created:**
- `MessageAIApp.swift` (modify)
- `GoogleService-Info.plist` (add)
- `Services/FirebaseManager.swift` (create)
- `Utilities/Constants.swift` (create)

**Files Modified:**
- Project configuration
- Info.plist (add Firebase URLs)

---

### PR #2: Authentication System ✅ UNIT TEST REQUIRED
**Branch:** `feature/authentication`  
**Estimated Time:** 2-3 hours (+ 30 mins for tests)  
**Description:** Implement email/password auth with Firebase, session management

**Tasks:**
- [ ] Enable Firebase Authentication (Email/Password) in Firebase Console
- [ ] Create `User` model with id, email, displayName, profilePictureUrl, lastSeen
- [ ] Create `AuthService.swift` with sign up, login, logout, auth state listener
- [ ] Create `AuthViewModel.swift` for state management
- [ ] Build `LoginView.swift` with email/password fields
- [ ] Build `SignUpView.swift` with name, email, password fields
- [ ] Create `AuthContainerView.swift` to toggle between login/signup
- [ ] Add form validation (email format, password length)
- [ ] Add error handling (display Firebase error messages)
- [ ] **UNIT TESTS:** Create `AuthServiceTests.swift`
  - [ ] Test email validation logic
  - [ ] Test password validation (minimum 6 characters)
  - [ ] Test auth state changes (logged out → logged in)
- [ ] **INTEGRATION TEST:** Create `AuthFlowTests.swift`
  - [ ] Test complete signup flow (UI → Firebase)
  - [ ] Test login with valid credentials
  - [ ] Test logout functionality
- [ ] Test: Create account, logout, login again

**Files Created:**
- `Models/User.swift`
- `Services/AuthService.swift`
- `ViewModels/AuthViewModel.swift`
- `Views/Auth/LoginView.swift`
- `Views/Auth/SignUpView.swift`
- `Views/Auth/AuthContainerView.swift`
- `MessageAITests/AuthServiceTests.swift` ✅
- `MessageAIUITests/AuthFlowTests.swift` ✅

**Files Modified:**
- `MessageAIApp.swift` (add auth state listener)

**Test Verification Criteria:**
- ✅ All unit tests pass (email/password validation)
- ✅ Can create account programmatically in test
- ✅ Auth state listener fires correctly

---

### PR #3: User Profile Management ✅ UNIT TEST REQUIRED
**Branch:** `feature/user-profile`  
**Estimated Time:** 2 hours (+ 30 mins for tests)  
**Description:** User profiles stored in Firestore, profile picture support

**Tasks:**
- [ ] Enable Cloud Firestore in Firebase Console (start in test mode)
- [ ] Create `UserService.swift` for Firestore user CRUD operations
- [ ] Create Firestore security rules (users can only edit their own profile)
- [ ] Build `ProfileView.swift` to display current user info
- [ ] Build `EditProfileView.swift` to update display name
- [ ] Create `UserAvatarView.swift` component for profile pictures
- [ ] Add placeholder avatar (SF Symbol "person.circle.fill")
- [ ] Save user profile to Firestore on sign up
- [ ] **UNIT TESTS:** Create `UserServiceTests.swift`
  - [ ] Test createUser() creates document in Firestore
  - [ ] Test updateUser() updates existing document
  - [ ] Test fetchUser() retrieves correct user data
  - [ ] Test updateLastSeen() updates timestamp
- [ ] Test: Update display name, verify in Firestore Console

**Files Created:**
- `Services/UserService.swift`
- `ViewModels/ProfileViewModel.swift`
- `Views/Profile/ProfileView.swift`
- `Views/Profile/EditProfileView.swift`
- `Views/Components/UserAvatarView.swift`
- `MessageAITests/UserServiceTests.swift` ✅

**Files Modified:**
- `Services/AuthService.swift` (create user doc on signup)

**Test Verification Criteria:**
- ✅ All CRUD operations work in tests
- ✅ User document structure matches model
- ✅ Can update user fields without overwriting others

---

### PR #4: Chat List & Navigation
**Branch:** `feature/chat-list`  
**Estimated Time:** 2 hours  
**Description:** Main navigation, chat list UI, conversation structure

**Tasks:**
- [ ] Create `Conversation` model (id, participants, lastMessage, lastMessageTime, type)
- [ ] Create `ChatService.swift` with method to fetch user's conversations
- [ ] Create `ChatListViewModel.swift` to manage conversation list state
- [ ] Build `MainTabView.swift` with two tabs: Chats, Profile
- [ ] Build `ChatListView.swift` with List of conversations
- [ ] Create conversation row UI (avatar, name, last message preview, timestamp)
- [ ] Build `NewChatView.swift` to start new conversation (select user)
- [ ] Add "+ New Chat" button in navigation bar
- [ ] Add real-time listener for conversation updates
- [ ] Test: Create conversation in Firestore manually, see it appear in list

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

### PR #5: Core 1:1 Messaging ✅ UNIT TEST + INTEGRATION TEST REQUIRED
**Branch:** `feature/core-messaging`  
**Estimated Time:** 4-5 hours (+ 1 hour for tests)  
**Description:** Send/receive text messages, real-time sync, message persistence

**Tasks:**
- [ ] Create `Message` model (id, text, senderId, timestamp, conversationId, status, readBy)
- [ ] Create `MessageStatus` enum (sending, sent, delivered, read)
- [ ] Add message CRUD methods to `ChatService.swift`
- [ ] Implement Firestore structure: conversations/{id}/messages/{messageId}
- [ ] Create `ChatDetailViewModel.swift` with message list and send logic
- [ ] Build `ChatDetailView.swift` for message thread
- [ ] Build `MessageRow.swift` for individual message bubbles (sender on right, receiver on left)
- [ ] Build `MessageInputView.swift` with TextField and Send button
- [ ] Implement optimistic UI (show message immediately with "sending" status)
- [ ] Add real-time listener for new messages in conversation
- [ ] Update conversation's lastMessage/lastMessageTime on send
- [ ] Add SwiftData for local message persistence
- [ ] Create `PersistenceController.swift` for SwiftData management
- [ ] Save messages to SwiftData on receive
- [ ] Load messages from SwiftData on app launch (offline support)
- [ ] **UNIT TESTS:** Create `ChatServiceTests.swift`
  - [ ] Test sendMessage() creates message in Firestore
  - [ ] Test fetchMessages() returns messages in correct order (newest first)
  - [ ] Test optimistic message creation (local ID → server ID)
  - [ ] Test message status transitions (sending → sent → delivered)
- [ ] **UNIT TESTS:** Create `PersistenceControllerTests.swift`
  - [ ] Test saveMessage() persists to SwiftData
  - [ ] Test fetchLocalMessages() retrieves from SwiftData
  - [ ] Test message deduplication (don't save duplicate messages)
- [ ] **INTEGRATION TEST:** Create `MessagingFlowTests.swift`
  - [ ] Test end-to-end message send/receive between two users
  - [ ] Test message appears in sender's UI immediately
  - [ ] Test message persists after app restart
- [ ] Test: Send message from User A, appears on User B's device in real-time

**Files Created:**
- `Models/Message.swift`
- `Models/MessageStatus.swift`
- `ViewModels/ChatDetailViewModel.swift`
- `Views/Chat/ChatDetailView.swift`
- `Views/Chat/MessageRow.swift`
- `Views/Chat/MessageInputView.swift`
- `Persistence/MessageAIDataModel.xcdatamodeld`
- `Persistence/PersistenceController.swift`
- `MessageAITests/ChatServiceTests.swift` ✅
- `MessageAITests/PersistenceControllerTests.swift` ✅
- `MessageAIUITests/MessagingFlowTests.swift` ✅

**Files Modified:**
- `Services/ChatService.swift` (add message methods)

**Test Verification Criteria:**
- ✅ All unit tests pass (send, fetch, persist)
- ✅ Integration test proves end-to-end messaging works
- ✅ Messages survive app termination (persistence test)
- ✅ No duplicate messages in local storage

---

### PR #6: Real-Time Features (Typing, Presence)
**Branch:** `feature/realtime-indicators`  
**Estimated Time:** 2 hours  
**Description:** Typing indicators and online/offline status

**Tasks:**
- [ ] Add `isTyping` field to conversations in Firestore
- [ ] Add typing indicator logic to `ChatDetailViewModel.swift`
- [ ] Send typing event when user types (debounced to 1 update per 3 seconds)
- [ ] Create `TypingIndicatorView.swift` component
- [ ] Display typing indicator in `ChatDetailView.swift`
- [ ] Add `lastSeen` timestamp to User model
- [ ] Update user's lastSeen on app foreground/background
- [ ] Create `OnlineStatusView.swift` component (green dot if online within 5 mins)
- [ ] Display online status in chat list and message thread
- [ ] Test: Type in one device, see "is typing..." on other device

**Files Created:**
- `Views/Chat/TypingIndicatorView.swift`
- `Views/Components/OnlineStatusView.swift`

**Files Modified:**
- `ViewModels/ChatDetailViewModel.swift` (typing logic)
- `Services/UserService.swift` (update lastSeen)
- `Views/Chat/ChatDetailView.swift` (show typing indicator)
- `Views/Chat/ChatListView.swift` (show online status)

---

### PR #7: Message Status & Read Receipts ✅ UNIT TEST REQUIRED
**Branch:** `feature/message-status`  
**Estimated Time:** 2 hours (+ 30 mins for tests)  
**Description:** Delivery states, read receipts, checkmarks

**Tasks:**
- [ ] Update message status to "sent" when Firestore confirms write
- [ ] Add listener in `ChatService.swift` to update status to "delivered" when recipient receives
- [ ] Implement read receipt logic: update `readBy` array when user opens chat
- [ ] Mark all messages as read when ChatDetailView appears
- [ ] Create checkmark icons (gray = sending, single = sent, double = delivered, blue double = read)
- [ ] Display checkmarks in `MessageRow.swift` for sender's messages only
- [ ] Add batch read update for efficiency
- [ ] **UNIT TESTS:** Create `MessageStatusTests.swift`
  - [ ] Test status transition: sending → sent
  - [ ] Test status transition: sent → delivered
  - [ ] Test status transition: delivered → read
  - [ ] Test readBy array updates correctly
  - [ ] Test batch marking messages as read
  - [ ] Test read receipts only update for recipient's messages
- [ ] Test: Send message, verify status progression (sending → sent → delivered → read)

**Files Modified:**
- `Services/ChatService.swift` (read receipt logic)
- `ViewModels/ChatDetailViewModel.swift` (mark as read)
- `Views/Chat/MessageRow.swift` (display checkmarks)
- `Models/Message.swift` (ensure readBy array exists)
- `MessageAITests/MessageStatusTests.swift` ✅

**Test Verification Criteria:**
- ✅ Status transitions happen in correct order
- ✅ Read receipts don't fire for sender's own messages
- ✅ Batch read updates work efficiently (single Firestore write)

---

### PR #8: Group Chat ✅ INTEGRATION TEST REQUIRED
**Branch:** `feature/group-chat`  
**Estimated Time:** 3-4 hours (+ 45 mins for tests)  
**Description:** Create groups, multi-participant messaging

**Tasks:**
- [ ] Update `Conversation` model to support group chat (add `name`, `isGroup`, `participants[]`)
- [ ] Create `GroupChatViewModel.swift` for group logic
- [ ] Build `CreateGroupView.swift` with name input and member selection
- [ ] Build `MemberSelectionView.swift` to select multiple users
- [ ] Build `GroupDetailView.swift` to view/edit group info
- [ ] Update `ChatService.swift` to handle group message distribution
- [ ] Update `MessageRow.swift` to show sender name/avatar in group chats
- [ ] Add group icon to chat list (show member avatars or group icon)
- [ ] Implement group-level read receipts (show count of who read)
- [ ] Add "Create Group" option in NewChatView
- [ ] **UNIT TESTS:** Create `GroupChatServiceTests.swift`
  - [ ] Test createGroup() creates conversation with multiple participants
  - [ ] Test addMember() adds participant to group
  - [ ] Test group message is saved with correct sender attribution
- [ ] **INTEGRATION TEST:** Create `GroupChatFlowTests.swift`
  - [ ] Test create group with 3 users
  - [ ] Test send message to group (all 3 users receive)
  - [ ] Test group read receipts (count updates correctly)
  - [ ] Test message sender attribution in group
- [ ] Test: Create group with 3 users, send messages, all users see messages

**Files Created:**
- `ViewModels/GroupChatViewModel.swift`
- `Views/Group/CreateGroupView.swift`
- `Views/Group/GroupDetailView.swift`
- `Views/Group/MemberSelectionView.swift`
- `MessageAITests/GroupChatServiceTests.swift` ✅
- `MessageAIUITests/GroupChatFlowTests.swift` ✅

**Files Modified:**
- `Models/Conversation.swift` (add group fields)
- `Services/ChatService.swift` (group message logic)
- `Views/Chat/MessageRow.swift` (show sender in groups)
- `Views/Chat/ChatListView.swift` (group icons)
- `Views/Chat/NewChatView.swift` (add group option)

**Test Verification Criteria:**
- ✅ Can create group programmatically in test
- ✅ All participants receive group messages
- ✅ Sender attribution displays correctly
- ✅ Group read receipts count accurately

---

### PR #9: Image Support ✅ UNIT TEST REQUIRED
**Branch:** `feature/image-messaging`  
**Estimated Time:** 2-3 hours (+ 30 mins for tests)  
**Description:** Send/receive images, Firebase Storage integration

**Tasks:**
- [ ] Enable Firebase Cloud Storage in Firebase Console
- [ ] Create `StorageService.swift` for image upload/download
- [ ] Create `ImageCompressor.swift` utility (compress to max 1920px, JPEG 0.7 quality)
- [ ] Create `ImagePickerView.swift` using PhotosUI
- [ ] Add `mediaUrl` and `mediaType` fields to Message model
- [ ] Update `MessageInputView.swift` to add image picker button
- [ ] Implement image upload flow (compress → upload → send message with URL)
- [ ] Show upload progress indicator
- [ ] Update `MessageRow.swift` to display images using AsyncImage
- [ ] Add tap-to-expand image functionality
- [ ] Update SwiftData persistence to save image URLs
- [ ] **UNIT TESTS:** Create `ImageCompressionTests.swift`
  - [ ] Test image compression reduces file size
  - [ ] Test compressed image max width is 1920px
  - [ ] Test JPEG quality is ~0.7
  - [ ] Test compression maintains aspect ratio
- [ ] **UNIT TESTS:** Create `StorageServiceTests.swift`
  - [ ] Test uploadImage() returns valid URL
  - [ ] Test upload progress reports correctly
  - [ ] Test upload handles errors gracefully
- [ ] Test: Send image, appears on recipient's device

**Files Created:**
- `Services/StorageService.swift`
- `Utilities/ImageCompressor.swift`
- `Views/Components/ImagePickerView.swift`
- `MessageAITests/ImageCompressionTests.swift` ✅
- `MessageAITests/StorageServiceTests.swift` ✅

**Files Modified:**
- `Models/Message.swift` (add mediaUrl, mediaType)
- `Views/Chat/MessageInputView.swift` (image picker button)
- `ViewModels/ChatDetailViewModel.swift` (image send logic)
- `Views/Chat/MessageRow.swift` (display images)

**Test Verification Criteria:**
- ✅ Images compress to reasonable size (<500KB for typical photo)
- ✅ Compression maintains visual quality
- ✅ Upload succeeds and returns valid Firebase Storage URL
- ✅ Image messages persist correctly

---

### PR #10: Offline Support & Message Queue ✅ UNIT TEST + INTEGRATION TEST REQUIRED
**Branch:** `feature/offline-support`  
**Estimated Time:** 2-3 hours (+ 1 hour for tests)  
**Description:** Message queuing, network monitoring, offline resilience

**Tasks:**
- [ ] Create `NetworkMonitor.swift` using NWPathMonitor
- [ ] Add network status publisher to app
- [ ] Implement message queue in SwiftData (pending messages table)
- [ ] Save outgoing messages to queue with "pending" status
- [ ] Add retry logic in `ChatService.swift` for failed sends
- [ ] Implement background task to send queued messages when online
- [ ] Handle app lifecycle (foreground/background) in `MessageAIApp.swift`
- [ ] Add network error handling and user feedback
- [ ] Implement idempotent sends (use message ID as Firestore doc ID)
- [ ] **UNIT TESTS:** Create `NetworkMonitorTests.swift`
  - [ ] Test network status detection (online/offline)
  - [ ] Test status change notifications
- [ ] **UNIT TESTS:** Create `MessageQueueTests.swift`
  - [ ] Test adding message to queue when offline
  - [ ] Test queue persists messages correctly
  - [ ] Test dequeue after successful send
  - [ ] Test retry logic (exponential backoff)
  - [ ] Test idempotent message IDs (no duplicates)
- [ ] **INTEGRATION TEST:** Create `OfflineMessagingTests.swift`
  - [ ] Test send message while offline → message queues
  - [ ] Test go online → queued messages send automatically
  - [ ] Test force quit with pending messages → reopen → messages send
  - [ ] Test rapid-fire messages while offline (queue multiple)
- [ ] Test offline scenarios:
  - [ ] Send message while offline → go online → message sends
  - [ ] Force quit mid-send → reopen app → message sends
  - [ ] Airplane mode → send 5 messages → disable airplane mode → all send

**Files Created:**
- `Services/NetworkMonitor.swift`
- `MessageAITests/NetworkMonitorTests.swift` ✅
- `MessageAITests/MessageQueueTests.swift` ✅
- `MessageAIUITests/OfflineMessagingTests.swift` ✅

**Files Modified:**
- `Persistence/PersistenceController.swift` (add pending messages queue)
- `Services/ChatService.swift` (queue and retry logic)
- `ViewModels/ChatDetailViewModel.swift` (check network status)
- `MessageAIApp.swift` (app lifecycle handling)

**Test Verification Criteria:**
- ✅ Messages queue when offline
- ✅ Queue automatically processes when online
- ✅ No duplicate messages sent
- ✅ Force quit recovery works
- ✅ Multiple queued messages send in order

---

### PR #11: Push Notifications
**Branch:** `feature/push-notifications`  
**Estimated Time:** 2-3 hours  
**Description:** Firebase Cloud Messaging, foreground/background notifications

**Tasks:**
- [ ] Enable Firebase Cloud Messaging in Firebase Console
- [ ] Create `NotificationService.swift` for FCM setup
- [ ] Request notification permissions on app launch
- [ ] Register device token with Firebase
- [ ] Store FCM token in user's Firestore document
- [ ] Implement foreground notification handler
- [ ] Display notification banner when app is active
- [ ] Add notification badge to app icon
- [ ] Create Firebase Cloud Function to send notifications on new message (stretch goal)
- [ ] Handle notification tap to open specific chat
- [ ] Test: Send message while app is in foreground → notification appears

**Files Created:**
- `Services/NotificationService.swift`

**Files Modified:**
- `MessageAIApp.swift` (register for notifications)
- `Models/User.swift` (add fcmToken field)
- `Services/UserService.swift` (save FCM token)

---

### PR #12: Polish & Bug Fixes
**Branch:** `feature/mvp-polish`  
**Estimated Time:** 2-3 hours  
**Description:** Final testing, UI polish, error handling

**Tasks:**
- [ ] Add loading states to all views
- [ ] Create `LoadingView.swift` component
- [ ] Improve error messages (user-friendly text)
- [ ] Add empty states (no conversations, no messages)
- [ ] Polish message bubble design (colors, spacing, shadows)
- [ ] Add haptic feedback for send button
- [ ] Improve timestamp formatting (`DateFormatter+Extensions.swift`)
- [ ] Add pull-to-refresh on chat list
- [ ] Optimize Firestore queries (add indexes if needed)
- [ ] Test all MVP requirements:
  - [ ] Real-time messaging between 2 devices
  - [ ] Message persistence after restart
  - [ ] Optimistic UI updates
  - [ ] Offline → online transition
  - [ ] Group chat with 3+ users
  - [ ] Read receipts
  - [ ] Image sending
  - [ ] App force quit recovery
  - [ ] Push notifications
  - [ ] Online/offline status
- [ ] Fix any bugs discovered during testing
- [ ] Prepare demo video script

**Files Created:**
- `Views/Components/LoadingView.swift`
- `Utilities/DateFormatter+Extensions.swift`

**Files Modified:**
- All View files (add loading/error states)
- `Utilities/Extensions.swift` (add helpers)

---

## Post-MVP: AI Features Phase (Days 2-7)

### PR #13: AI Infrastructure Setup ✅ UNIT TEST REQUIRED
**Branch:** `feature/ai-infrastructure`  
**Estimated Time:** 2-3 hours (+ 30 mins for tests)  
**Description:** Firebase Cloud Functions, OpenAI/Claude API integration

**Tasks:**
- [ ] Initialize Firebase Cloud Functions project
- [ ] Install AI SDK dependencies (OpenAI or Anthropic)
- [ ] Create Cloud Function for AI chat endpoint
- [ ] Implement secure API key storage (Firebase environment config)
- [ ] Create `AIService.swift` in iOS app to call Cloud Functions
- [ ] Add conversation history retrieval (RAG pipeline basics)
- [ ] **UNIT TESTS:** Create `AIServiceTests.swift`
  - [ ] Test Cloud Function endpoint is reachable
  - [ ] Test API request/response format
  - [ ] Test error handling (API key invalid, timeout, etc.)
  - [ ] Test conversation history retrieval
- [ ] Test: Call AI function from app, get response

**Files Created:**
- `functions/index.js` (Cloud Functions)
- `functions/package.json`
- `Services/AIService.swift`
- `ViewModels/AIViewModel.swift`
- `MessageAITests/AIServiceTests.swift` ✅

**Test Verification Criteria:**
- ✅ Cloud Function responds successfully
- ✅ API errors handled gracefully
- ✅ Conversation history retrieves correctly

---

### PR #14: AI Chat Interface
**Branch:** `feature/ai-chat-interface`  
**Estimated Time:** 3-4 hours  
**Description:** Dedicated AI assistant chat

**Tasks:**
- [ ] Create AI conversation type in Firestore
- [ ] Build `AIChatView.swift` for AI assistant interface
- [ ] Add "AI Assistant" tab to MainTabView
- [ ] Implement streaming responses (if supported)
- [ ] Add context: let AI access user's message history
- [ ] Create AI avatar/branding
- [ ] Test: Ask AI a question about conversations

**Files Created:**
- `Views/AI/AIChatView.swift`
- `ViewModels/AIChatViewModel.swift`

**Files Modified:**
- `Views/Main/MainTabView.swift` (add AI tab)

---

### PR #15: Required AI Feature #1 - Smart Calendar Extraction ✅ UNIT TEST REQUIRED
**Branch:** `feature/ai-calendar-extraction`  
**Estimated Time:** 4-5 hours (+ 45 mins for tests)  
**Description:** Detect dates/times/events in messages

**Tasks:**
- [ ] Create Cloud Function for calendar extraction using LLM
- [ ] Implement prompt engineering for date/time parsing
- [ ] Add function calling for structured output (date, time, event)
- [ ] Create UI indicator for detected events (chip/badge on message)
- [ ] Build calendar export functionality (iCal format)
- [ ] Add "Add to Calendar" button on detected events
- [ ] **UNIT TESTS:** Create `CalendarExtractionTests.swift`
  - [ ] Test extraction of explicit dates ("December 25th")
  - [ ] Test extraction of relative dates ("next Tuesday", "tomorrow")
  - [ ] Test extraction of times ("at 3pm", "4:30 PM")
  - [ ] Test extraction of events ("soccer practice", "doctor appointment")
  - [ ] Test multiple events in one message
  - [ ] Test edge cases (no dates, ambiguous dates)
- [ ] Test with various date formats ("next Tuesday", "12/25", "tomorrow at 3pm")

**Files Created:**
- `functions/calendarExtractor.js`
- `Views/Components/EventChipView.swift`
- `MessageAITests/CalendarExtractionTests.swift` ✅

**Files Modified:**
- `Services/AIService.swift` (calendar extraction endpoint)
- `Views/Chat/MessageRow.swift` (show event chips)

**Test Verification Criteria:**
- ✅ Correctly parses various date formats
- ✅ Extracts time with event
- ✅ Handles ambiguous/missing dates gracefully
- ✅ Outputs structured data (ISO date format)

---

### PR #16: Required AI Feature #2 - Decision Summarization
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
- [ ] Test on long group chat threads (50+ messages)

**Files Created:**
- `functions/decisionSummarizer.js`
- `Views/AI/DecisionSummaryView.swift`

**Files Modified:**
- `Services/AIService.swift` (summary endpoint)
- `Views/Chat/ChatDetailView.swift` (summary button)

---

### PR #17: Required AI Feature #3 - Priority Message Highlighting ✅ UNIT TEST REQUIRED
**Branch:** `feature/ai-priority-detection`  
**Estimated Time:** 4-5 hours (+ 45 mins for tests)  
**Description:** Auto-detect urgent/important messages

**Tasks:**
- [ ] Create Cloud Function for priority detection
- [ ] Implement sentiment + urgency analysis with LLM
- [ ] Define priority levels (urgent, important, normal)
- [ ] Add `priority` field to Message model
- [ ] Run priority detection on incoming messages (background)
- [ ] Update `MessageRow.swift` to highlight urgent messages (red border/icon)
- [ ] Add filter in ChatListView to show priority messages
- [ ] **UNIT TESTS:** Create `PriorityDetectionTests.swift`
  - [ ] Test urgent keywords detected ("emergency", "urgent", "ASAP")
  - [ ] Test important messages vs normal
  - [ ] Test all-caps messages flagged as urgent
  - [ ] Test exclamation marks increase priority
  - [ ] Test normal messages not falsely flagged
  - [ ] Test priority levels (urgent > important > normal)
- [ ] Test with urgent keywords ("emergency", "ASAP", "school closed")

**Files Created:**
- `functions/priorityDetector.js`
- `MessageAITests/PriorityDetectionTests.swift` ✅

**Files Modified:**
- `Models/Message.swift` (add priority field)
- `Services/AIService.swift` (priority detection endpoint)
- `Views/Chat/MessageRow.swift` (priority styling)
- `Views/Chat/ChatListView.swift` (priority filter)

**Test Verification Criteria:**
- ✅ Urgent messages correctly identified
- ✅ False positive rate is low (<5%)
- ✅ Priority levels assigned correctly
- ✅ Edge cases handled (empty messages, emojis only)

---

### PR #18: Required AI Feature #4 - RSVP Tracking ✅ UNIT TEST REQUIRED
**Branch:** `feature/ai-rsvp-tracking`  
**Estimated Time:** 4-5 hours (+ 45 mins for tests)  
**Description:** Track event confirmations in group chats

**Tasks:**
- [ ] Create Cloud Function to detect RSVP requests
- [ ] Identify invitation messages (LLM pattern matching)
- [ ] Parse responses ("I can come", "count me in", "can't make it")
- [ ] Create RSVP data structure (event, yesCount, noCount, maybeCount)
- [ ] Build `RSVPTrackerView.swift` to display headcount
- [ ] Show RSVP summary below invitation message
- [ ] Add manual RSVP buttons (Yes/No/Maybe)
- [ ] **UNIT TESTS:** Create `RSVPTrackingTests.swift`
  - [ ] Test invitation detection ("Can you come to...", "Who's available for...")
  - [ ] Test positive responses ("Yes", "I'll be there", "Count me in")
  - [ ] Test negative responses ("No", "Can't make it", "Sorry")
  - [ ] Test maybe responses ("Maybe", "Not sure", "Tentative")
  - [ ] Test RSVP count aggregation
  - [ ] Test multiple RSVPs from same user (latest wins)
- [ ] Test with various invitation formats

**Files Created:**
- `functions/rsvpTracker.js`
- `Views/AI/RSVPTrackerView.swift`
- `Models/RSVPEvent.swift`
- `MessageAITests/RSVPTrackingTests.swift` ✅

**Files Modified:**
- `Services/AIService.swift` (RSVP endpoints)
- `Views/Chat/MessageRow.swift` (RSVP UI)

**Test Verification Criteria:**
- ✅ Invitation messages correctly identified
- ✅ Response sentiment classified accurately
- ✅ Counts aggregate correctly
- ✅ Updates when user changes response

---

### PR #19: Required AI Feature #5 - Deadline/Reminder Extraction ✅ UNIT TEST REQUIRED
**Branch:** `feature/ai-deadline-extraction`  
**Estimated Time:** 4-5 hours (+ 45 mins for tests)  
**Description:** Auto-detect deadlines and set reminders

**Tasks:**
- [ ] Create Cloud Function for deadline detection
- [ ] Identify deadline patterns ("due Friday", "by end of week", "permission slip deadline")
- [ ] Extract: task, deadline date/time, context
- [ ] Create reminder system (local notifications)
- [ ] Build `DeadlineListView.swift` to show all upcoming deadlines
- [ ] Add reminder notification 24 hours before deadline
- [ ] Allow users to snooze/dismiss reminders
- [ ] **UNIT TESTS:** Create `DeadlineExtractionTests.swift`
  - [ ] Test deadline keywords ("due", "deadline", "by", "submit by")
  - [ ] Test date extraction with deadlines
  - [ ] Test task extraction ("permission slip", "homework", "form")
  - [ ] Test relative deadlines ("by end of week", "in 3 days")
  - [ ] Test deadline without explicit date (defaults to context)
  - [ ] Test reminder scheduling (24 hours before)
- [ ] Test with various deadline formats

**Files Created:**
- `functions/deadlineExtractor.js`
- `Views/AI/DeadlineListView.swift`
- `Models/Deadline.swift`
- `MessageAITests/DeadlineExtractionTests.swift` ✅

**Files Modified:**
- `Services/AIService.swift` (deadline endpoint)
- `Services/NotificationService.swift` (reminder notifications)

**Test Verification Criteria:**
- ✅ Deadline patterns correctly identified
- ✅ Task and date extracted accurately
- ✅ Reminder schedules at correct time
- ✅ Past deadlines not scheduled

---

### PR #20: Advanced AI Feature - Proactive Assistant ✅ INTEGRATION TEST REQUIRED
**Branch:** `feature/ai-proactive-assistant`  
**Estimated Time:** 6-8 hours (+ 1 hour for tests)  
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
- [ ] **UNIT TESTS:** Create `ProactiveAssistantTests.swift`
  - [ ] Test conflict detection (message time vs calendar event)
  - [ ] Test suggestion generation quality
  - [ ] Test calendar access permissions
  - [ ] Test no false positive conflicts
- [ ] **INTEGRATION TEST:** Create `ProactiveAssistantFlowTests.swift`
  - [ ] Test: Receive message requesting time slot during existing event → conflict alert shows
  - [ ] Test: Tap suggested response → inserts into message field
  - [ ] Test: No calendar events → no conflicts detected
  - [ ] Test: Multiple conflicts in one day
- [ ] Test conflict scenarios

**Files Created:**
- `functions/proactiveAssistant.js`
- `Views/AI/ConflictAlertView.swift`
- `Services/CalendarService.swift`
- `MessageAITests/ProactiveAssistantTests.swift` ✅
- `MessageAIUITests/ProactiveAssistantFlowTests.swift` ✅

**Files Modified:**
- `ViewModels/ChatDetailViewModel.swift` (conflict detection)
- `Views/Chat/MessageInputView.swift` (suggestion chips)

**Test Verification Criteria:**
- ✅ Calendar conflicts accurately detected
- ✅ Suggestions are contextually appropriate
- ✅ Alerts appear proactively (not on-demand)
- ✅ Performance impact is minimal

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
- [ ] All new features tested on device/simulator
- [ ] **All unit tests pass (if PR has tests)**
- [ ] **All integration tests pass (if PR has tests)**
- [ ] No console errors or warnings
- [ ] Code follows Swift style guide
- [ ] Comments added for complex logic
- [ ] PR description includes screenshots/demo if UI changes

---

## Running Tests

### Unit Tests (MessageAITests/)
**Run in Xcode:**
1. Press `Cmd + U` to run all tests
2. Or click the diamond icon next to test function
3. View results in Test Navigator (`Cmd + 6`)

**Run from Command Line:**
```bash
xcodebuild test -scheme MessageAI -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'
```

**What to Check:**
- ✅ All tests show green checkmarks
- ✅ Code coverage >70% for tested services
- ✅ No flaky tests (tests that randomly fail)

### Integration Tests (MessageAIUITests/)
**Run in Xcode:**
1. Select `MessageAIUITests` scheme
2. Press `Cmd + U`
3. Watch UI automation execute

**What to Check:**
- ✅ UI flows complete without crashes
- ✅ End-to-end scenarios work (login → send message → receive)
- ✅ Tests clean up after themselves (no leftover data)

### Test Verification After Each PR
**For PRs with ✅ marks:**
1. Run unit tests: `Cmd + U`
2. Verify all tests pass
3. If tests fail, debug before merging PR
4. Add test results screenshot to PR description

**Red Flag Scenarios:**
- 🚩 Test compiles but always passes (not actually testing anything)
- 🚩 Test fails intermittently (timing issues, race conditions)
- 🚩 Test passes but feature is broken (test is incorrect)

**Pro Tip:** Use Test-Driven Development (TDD) for complex logic
1. Write test first (it fails)
2. Implement feature
3. Test passes ✅
4. Refactor code, test still passes

---

## Example Test Code (Reference for AI Agents)

### Example 1: Unit Test (AuthService)
```swift
import XCTest
@testable import MessageAI

final class AuthServiceTests: XCTestCase {
    var authService: AuthService!
    
    override func setUp() {
        super.setUp()
        authService = AuthService()
    }
    
    func testEmailValidation() {
        // Valid emails
        XCTAssertTrue(authService.isValidEmail("user@example.com"))
        XCTAssertTrue(authService.isValidEmail("test.user+tag@domain.co.uk"))
        
        // Invalid emails
        XCTAssertFalse(authService.isValidEmail("notanemail"))
        XCTAssertFalse(authService.isValidEmail("@example.com"))
        XCTAssertFalse(authService.isValidEmail("user@"))
    }
    
    func testPasswordValidation() {
        // Valid passwords (6+ characters)
        XCTAssertTrue(authService.isValidPassword("password123"))
        XCTAssertTrue(authService.isValidPassword("123456"))
        
        // Invalid passwords (< 6 characters)
        XCTAssertFalse(authService.isValidPassword("12345"))
        XCTAssertFalse(authService.isValidPassword(""))
    }
    
    func testSignUpCreatesUser() async throws {
        let email = "test\(UUID())@example.com" // Unique email
        let password = "testpassword"
        let displayName = "Test User"
        
        let user = try await authService.signUp(
            email: email,
            password: password,
            displayName: displayName
        )
        
        XCTAssertNotNil(user)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.displayName, displayName)
        
        // Cleanup
        try await authService.deleteAccount()
    }
}
```

### Example 2: Unit Test (Message Queue)
```swift
import XCTest
@testable import MessageAI

final class MessageQueueTests: XCTestCase {
    var chatService: ChatService!
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true) // Use in-memory for tests
        chatService = ChatService(persistence: persistenceController)
    }
    
    func testMessageQueuesWhenOffline() async {
        // Simulate offline mode
        chatService.isOnline = false
        
        let message = Message(
            id: UUID().uuidString,
            text: "Test message",
            senderId: "user123",
            conversationId: "conv456",
            timestamp: Date(),
            status: .sending
        )
        
        // Try to send message while offline
        await chatService.sendMessage(message)
        
        // Verify message is in queue
        let queuedMessages = await persistenceController.getPendingMessages()
        XCTAssertEqual(queuedMessages.count, 1)
        XCTAssertEqual(queuedMessages.first?.id, message.id)
    }
    
    func testQueueProcessesWhenOnline() async {
        // Add message to queue while offline
        chatService.isOnline = false
        let message = Message(...)
        await chatService.sendMessage(message)
        
        // Go online
        chatService.isOnline = true
        await chatService.processQueue()
        
        // Verify queue is empty (messages sent)
        let queuedMessages = await persistenceController.getPendingMessages()
        XCTAssertEqual(queuedMessages.count, 0)
    }
    
    func testIdempotentSends() async {
        let messageId = UUID().uuidString
        let message = Message(id: messageId, ...)
        
        // Send same message twice
        await chatService.sendMessage(message)
        await chatService.sendMessage(message) // Should be ignored
        
        // Verify only one message exists in Firestore
        let messages = await chatService.fetchMessages(conversationId: message.conversationId)
        let matchingMessages = messages.filter { $0.id == messageId }
        XCTAssertEqual(matchingMessages.count, 1)
    }
}
```

### Example 3: Integration Test (End-to-End Messaging)
```swift
import XCTest

final class MessagingFlowTests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }
    
    func testSendAndReceiveMessage() {
        // Login as User A
        loginAs(email: "usera@test.com", password: "password")
        
        // Navigate to chat with User B
        app.tables.staticTexts["User B"].tap()
        
        // Type and send message
        let messageField = app.textFields["messageInput"]
        messageField.tap()
        messageField.typeText("Hello from User A!")
        app.buttons["sendButton"].tap()
        
        // Verify message appears immediately (optimistic UI)
        XCTAssertTrue(app.staticTexts["Hello from User A!"].exists)
        
        // Verify checkmark shows "sending" then "sent"
        let sendingCheckmark = app.images["checkmark.circle"]
        XCTAssertTrue(sendingCheckmark.waitForExistence(timeout: 1))
        
        let sentCheckmark = app.images["checkmark.circle.fill"]
        XCTAssertTrue(sentCheckmark.waitForExistence(timeout: 5))
        
        // Logout User A
        app.buttons["profileTab"].tap()
        app.buttons["logoutButton"].tap()
        
        // Login as User B
        loginAs(email: "userb@test.com", password: "password")
        
        // Verify message from User A appears
        app.tables.staticTexts["User A"].tap()
        XCTAssertTrue(app.staticTexts["Hello from User A!"].exists)
    }
    
    func testMessagePersistsAfterRestart() {
        // Send message
        loginAs(email: "usera@test.com", password: "password")
        sendMessage("Test persistence")
        
        // Force quit app (simulate)
        app.terminate()
        
        // Relaunch
        app.launch()
        
        // Re-login
        loginAs(email: "usera@test.com", password: "password")
        
        // Verify message still exists
        app.tables.staticTexts["User B"].tap()
        XCTAssertTrue(app.staticTexts["Test persistence"].exists)
    }
    
    // Helper functions
    func loginAs(email: String, password: String) {
        let emailField = app.textFields["emailField"]
        emailField.tap()
        emailField.typeText(email)
        
        let passwordField = app.secureTextFields["passwordField"]
        passwordField.tap()
        passwordField.typeText(password)
        
        app.buttons["loginButton"].tap()
        
        // Wait for main screen
        XCTAssertTrue(app.tabBars.buttons["Chats"].waitForExistence(timeout: 5))
    }
    
    func sendMessage(_ text: String) {
        let messageField = app.textFields["messageInput"]
        messageField.tap()
        messageField.typeText(text)
        app.buttons["sendButton"].tap()
    }
}
```

### Example 4: Unit Test (AI Feature - Calendar Extraction)
```swift
import XCTest
@testable import MessageAI

final class CalendarExtractionTests: XCTestCase {
    var aiService: AIService!
    
    override func setUp() {
        super.setUp()
        aiService = AIService()
    }
    
    func testExtractExplicitDate() async throws {
        let message = "Soccer practice on December 25th at 3pm"
        let events = try await aiService.extractCalendarEvents(from: message)
        
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].title, "Soccer practice")
        XCTAssertEqual(events[0].date.month, 12)
        XCTAssertEqual(events[0].date.day, 25)
        XCTAssertEqual(events[0].time, "3pm")
    }
    
    func testExtractRelativeDate() async throws {
        let message = "Dentist appointment next Tuesday at 2:30pm"
        let events = try await aiService.extractCalendarEvents(from: message)
        
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].title, "Dentist appointment")
        
        // Verify "next Tuesday" resolves to correct date
        let nextTuesday = Date.nextWeekday(.tuesday)
        XCTAssertEqual(events[0].date.day, Calendar.current.component(.day, from: nextTuesday))
    }
    
    func testMultipleEvents() async throws {
        let message = "Piano lesson Monday 4pm and soccer practice Wednesday 5pm"
        let events = try await aiService.extractCalendarEvents(from: message)
        
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].title, "Piano lesson")
        XCTAssertEqual(events[1].title, "soccer practice")
    }
    
    func testNoEventsInMessage() async throws {
        let message = "Just saying hello!"
        let events = try await aiService.extractCalendarEvents(from: message)
        
        XCTAssertEqual(events.count, 0)
    }
}
```

### Key Testing Patterns

**1. Arrange-Act-Assert (AAA) Pattern**
```swift
func testExample() {
    // Arrange: Set up test data
    let message = Message(...)
    
    // Act: Perform action
    let result = service.processMessage(message)
    
    // Assert: Verify result
    XCTAssertEqual(result.status, .sent)
}
```

**2. Use Unique IDs for Test Data**
```swift
let testEmail = "test\(UUID())@example.com" // Prevents conflicts
```

**3. Clean Up After Tests**
```swift
override func tearDown() {
    // Delete test data
    try? await testUser.delete()
    super.tearDown()
}
```

**4. Test Edge Cases**
```swift
func testEmptyMessage() { ... }
func testVeryLongMessage() { ... }
func testSpecialCharacters() { ... }
```

**5. Use Expectations for Async Code**
```swift
func testAsyncOperation() {
    let expectation = expectation(description: "Async operation completes")
    
    service.asyncMethod { result in
        XCTAssertNotNil(result)
        expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
}
```

---

## Testing Checklist (After Each PR)

**Quick Smoke Test:**
- [ ] App launches
- [ ] No crashes in basic flow
- [ ] New feature works as expected

**MVP Gate Test (After PR #12):**
- [ ] Two users can chat in real-time
- [ ] Messages persist after restart
- [ ] Offline mode works
- [ ] Group chat with 3+ users works
- [ ] Images send/receive correctly
- [ ] Read receipts display
- [ ] Push notifications appear
- [ ] App survives force quit

---

## Progress Tracking

Track your progress by checking off PRs as you complete them:

**MVP Phase (24 Hours)**
- [ ] PR #1: Project Setup ✅
- [ ] PR #2: Authentication ✅
- [ ] PR #3: User Profile ✅
- [ ] PR #4: Chat List ✅
- [ ] PR #5: Core Messaging ✅
- [ ] PR #6: Real-Time Features ✅
- [ ] PR #7: Message Status ✅
- [ ] PR #8: Group Chat ✅
- [ ] PR #9: Image Support ✅
- [ ] PR #10: Offline Support ✅
- [ ] PR #11: Push Notifications ✅
- [ ] PR #12: Polish & Testing ✅

**AI Phase (Days 2-7)**
- [ ] PR #13: AI Infrastructure ✅
- [ ] PR #14: AI Chat Interface ✅
- [ ] PR #15: Calendar Extraction ✅
- [ ] PR #16: Decision Summarization ✅
- [ ] PR #17: Priority Detection ✅
- [ ] PR #18: RSVP Tracking ✅
- [ ] PR #19: Deadline Extraction ✅
- [ ] PR #20: Proactive Assistant ✅

**Final Deliverables**
- [ ] Demo video recorded ✅
- [ ] Persona Brainlift document written ✅
- [ ] TestFlight build uploaded ✅
- [ ] Social post published ✅

---

## Next Steps

1. **Start with PR #1:** Set up your Xcode project and Firebase
2. **Commit Early, Commit Often:** Push code after each subtask
3. **Test Between PRs:** Don't let bugs accumulate
4. **Use AI Agents Strategically:** Give them one PR at a time with full context

**Ready to start? Let's begin with PR #1: Project Setup & Firebase Integration!**