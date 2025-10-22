# MessageAI - Product Requirements Document (MVP)

**App Name:** Weftly (Firebase: "Weftly", Bundle ID: "com.sanjaykarinje.weftly")  
**Target Persona:** Busy Parent/Caregiver  
**Platform:** iOS (iPhone)  
**Timeline:** 24 hours to MVP checkpoint  
**Version:** 1.0 - MVP Only (AI features come post-MVP)

---

## Executive Summary

MessageAI is a cross-platform messaging app designed for busy parents who juggle multiple schedules, appointments, and family coordination. The MVP focuses on delivering **rock-solid messaging infrastructure** with real-time delivery, offline support, and group chat capabilities. AI features will be added after the core messaging experience is proven reliable.

---

## User Stories

### Primary Persona: Busy Parent/Caregiver

**Background:**
- Sarah is a working mom with two kids (ages 7 and 10)
- Coordinates schedules with her spouse, school, babysitters, and other parents
- Uses group chats for soccer team, PTA, family, and work
- Often in situations with poor connectivity (grocery stores, school parking lots)
- Needs quick, reliable communication without cognitive overhead

**Core User Stories:**

1. **As a busy parent**, I want to send quick messages to my spouse about pickup times, so we can coordinate without phone calls that interrupt meetings.

2. **As a soccer team coordinator**, I want to send updates to all parents in a group chat, so everyone gets practice schedule changes instantly.

3. **As a working parent**, I want messages to send even when I'm in areas with spotty cell service, so I don't have to remember to resend them later.

4. **As someone juggling multiple responsibilities**, I want to see at a glance who's read my messages, so I know if urgent information has been received.

5. **As a parent on-the-go**, I want to quickly share photos from school events with family members, so everyone stays connected.

6. **As a caregiver**, I want to see when other parents are typing responses, so I know if I should wait before sending a follow-up message.

7. **As a multitasking parent**, I want my message history to always be available, even offline, so I can reference previous conversations about appointments and schedules.

8. **As someone who values privacy**, I want secure authentication, so only authorized users can access our family conversations.

### Secondary User Stories (Group Chat)

9. **As a PTA member**, I want to create group chats with multiple parents, so we can coordinate school events efficiently.

10. **As a parent in multiple groups**, I want clear indicators of which messages are from which group, so I don't confuse soccer updates with family plans.

---

## MVP Feature Requirements

### ✅ Must-Have Features (Hard Gate for MVP)

#### 1. Authentication & User Management
- Email/password authentication
- User profile with display name
- Profile picture support
- Secure session management
- Logout functionality

#### 2. One-on-One Chat
- Send and receive text messages
- Real-time message delivery
- Message timestamps (friendly format: "Just now", "5m ago", "Yesterday 3:45 PM")
- Message persistence (survives app restart)
- Chat history accessible offline
- Optimistic UI (messages appear instantly before server confirmation)

#### 3. Message Delivery & Status
- Four message states:
  - **Sending** (gray checkmark)
  - **Sent** (single checkmark)
  - **Delivered** (double checkmark)
  - **Read** (blue double checkmark)
- Read receipts
- Delivery confirmation

#### 4. Real-Time Features
- Online/offline presence indicators (green dot = online)
- Typing indicators ("Sarah is typing...")
- Live message updates (no refresh needed)

#### 5. Group Chat
- Create groups with 3+ participants
- Add members to group
- Group name and icon
- Message attribution (show sender name/avatar in group)
- All members see messages in real-time
- Group-level read receipts

#### 6. Media Support
- Send images from camera roll
- Display images inline in chat
- Image upload progress indicator
- Image thumbnails in chat history

#### 7. Offline & Network Resilience
- Message queue for offline sends
- Auto-send when connectivity returns
- Handle airplane mode gracefully
- Recover from app force-quit
- Work on poor networks (3G, intermittent connectivity)

#### 8. Push Notifications
- Foreground notification experience implemented via local notification proxy (requests user permission, displays banner while app is active)
- Pending: APNs credential + physical device testing once Apple Developer enrollment is complete

#### 9. Core UI/UX
- Chat list view (all conversations)
- Chat detail view (message thread)
- New conversation flow
- Simple, clean interface optimized for quick interactions
- Large tap targets (accessibility for on-the-go use)

---

## Tech Stack

### Frontend (iOS)
- **Language:** Swift 5.10+
- **UI Framework:** SwiftUI
- **Minimum iOS:** iOS 17.0
- **Local Storage:** SwiftData (for message persistence)
- **Networking:** URLSession with async/await
- **Image Handling:** PhotosUI + AsyncImage

### Backend
- **Platform:** Firebase (Google Cloud)
- **Database:** Cloud Firestore (NoSQL, real-time)
- **Authentication:** Firebase Auth
- **Storage:** Firebase Cloud Storage (for images)
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Functions:** Firebase Cloud Functions (for future AI features)

### Development Tools
- **IDE:** Xcode 16.x
- **Package Manager:** Swift Package Manager (SPM)
- **Version Control:** Git + GitHub
- **Testing:** Two iOS devices (physical + simulator acceptable for MVP)

### Third-Party SDKs
- **Firebase iOS SDK** (via SPM):
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseStorage
  - FirebaseMessaging

---

## Tech Stack Decision Matrix

### ✅ Why Firebase?

**Pros:**
- **Real-time by default:** Firestore handles live sync automatically
- **Proven at scale:** Powers apps with billions of users
- **Fast MVP development:** Auth, database, storage in one platform
- **Generous free tier:** 50K daily reads, 20K writes, 1GB storage
- **Offline support built-in:** Firestore caches data automatically
- **Security rules:** Row-level security without writing backend code
- **Cloud Functions:** Ready for AI integration post-MVP

**Cons:**
- **Vendor lock-in:** Harder to migrate away later
- **Cost scaling:** Can get expensive at high volume (mitigated: this is MVP)
- **Limited query capabilities:** No full-text search (use Algolia later)
- **NoSQL limitations:** Requires denormalization

**Verdict:** Best choice for 24-hour MVP. Speed and real-time features outweigh concerns.

---

### ❓ Alternative: Supabase

**Pros:**
- PostgreSQL (relational database)
- Open-source (self-hostable)
- Better querying capabilities
- Competitive pricing

**Cons:**
- Real-time setup more complex
- Smaller community/fewer examples
- Less mature iOS SDK
- More manual configuration

**Verdict:** Great for production, but slower for MVP sprint.

---

### ❓ Alternative: Custom Backend (Node.js + PostgreSQL + WebSockets)

**Pros:**
- Complete control
- No vendor lock-in
- Optimized for your exact needs

**Cons:**
- **Time sink:** Would consume 50% of MVP timeline
- Real-time infrastructure is hard to build
- Push notifications require manual APNs setup
- Deployment complexity
- Infrastructure management

**Verdict:** Not viable for 24-hour timeline. Consider post-MVP.

---

### ✅ Why Swift + SwiftUI?

**Pros:**
- **Native performance:** Smoothest experience on iOS
- **SwiftUI maturity:** Excellent for rapid UI development
- **SwiftData integration:** Local persistence is trivial
- **Strong typing:** Catches errors at compile time
- **Modern async/await:** Clean networking code

**Cons:**
- iOS-only (can't reuse for Android)
- Learning curve if new to Swift

**Verdict:** Optimal for iOS MVP. React Native would add complexity without benefits at this stage.

---

## Potential Pitfalls & Mitigation

### 1. **Firestore Data Modeling**
**Risk:** Poor data structure leads to inefficient queries and scaling issues  
**Mitigation:**
- Use subcollections for messages under conversations
- Denormalize user data (store username in message for quick display)
- Index on timestamp for pagination
- Keep documents small (<1MB)

**Recommended Structure:**
```
users/
  {userId}/
    - name
    - profilePictureUrl
    - lastSeen
    
conversations/
  {conversationId}/
    - participants: [userId1, userId2]
    - lastMessage
    - lastMessageTime
    - type: "direct" | "group"
    
    messages/ (subcollection)
      {messageId}/
        - text
        - senderId
        - timestamp
        - status: "sending" | "sent" | "delivered" | "read"
        - readBy: [userId1, userId2]
        - mediaUrl (optional)
```

---

### 2. **Real-Time Listener Management**
**Risk:** Memory leaks from unremoved Firestore listeners  
**Mitigation:**
- Store listener references
- Remove listeners in `onDisappear` or `deinit`
- Use single listener per screen
- Test app backgrounding/foregrounding thoroughly

---

### 3. **Optimistic UI Sync Issues**
**Risk:** Local message appears, but never actually sends  
**Mitigation:**
- Store pending messages in SwiftData
- Retry failed sends on app launch
- Show error state if send fails after 3 retries
- Allow manual retry button

---

### 4. **Image Upload Size**
**Risk:** Users upload huge photos, consuming bandwidth/storage  
**Mitigation:**
- Compress images before upload (max 1920px width)
- Use JPEG compression (0.7 quality)
- Show upload progress
- Implement upload timeout (30 seconds)

---

### 5. **Push Notification Setup**
**Risk:** Complex APNs configuration causes delays  
**Mitigation:**
- Start with foreground notifications only for MVP
- Use Firebase Messaging (handles token management)
- Test notifications last (not critical for MVP gate)
- Background notifications are stretch goal

---

### 6. **Group Chat Scalability**
**Risk:** Large groups (50+ members) cause performance issues  
**Mitigation:**
- MVP limit: 20 members per group
- Paginate message loading (fetch 50 at a time)
- Lazy load member list
- Monitor Firestore read costs

---

### 7. **Offline Message Queue**
**Risk:** Messages get lost or duplicated during offline/online transitions  
**Mitigation:**
- Use unique message IDs (UUID)
- Mark messages as "pending" in SwiftData
- Implement idempotent sends (Firestore document ID = message ID)
- Clear pending flag only after Firestore confirmation

---

### 8. **Testing Complexity**
**Risk:** Hard to reproduce real-world scenarios (airplane mode, force quit)  
**Mitigation:**
- Use iOS Simulator network conditions (Settings → Developer)
- Test on physical device with airplane mode
- Force quit app mid-send to test recovery
- Create test checklist for each scenario

---

### 9. **Firebase Free Tier Limits**
**Risk:** Exceeding free tier during development/testing  
**Mitigation:**
- Monitor usage in Firebase Console
- Use Firestore emulator for local testing
- Implement pagination (don't load all messages)
- Delete test data regularly

**Free Tier Limits (per day):**
- 50,000 document reads
- 20,000 document writes
- 1GB storage
- 10GB bandwidth

---

## What's NOT in MVP

### Deferred to Post-MVP
- ✖ AI features (all 5 required + 1 advanced)
- ✖ Voice messages
- ✖ Video calls
- ✖ Message editing
- ✖ Message deletion
- ✖ Message reactions (emoji)
- ✖ Link previews
- ✖ Stickers/GIFs
- ✖ File attachments (PDFs, documents)
- ✖ End-to-end encryption
- ✖ Message search
- ✖ Chat archiving
- ✖ Block/report users
- ✖ Custom chat backgrounds
- ✖ Message forwarding
- ✖ Reply threading
- ✖ Pin messages
- ✖ @ mentions in groups
- ✖ Admin controls for groups
- ✖ Delivery statistics/analytics

### Why These Are Excluded
**Focus:** The MVP proves the messaging infrastructure is rock-solid. Adding more features before validating the core would introduce risk.

**Philosophy:** "A simple, reliable messaging app beats a feature-rich app with flaky message delivery."

---

## Success Criteria (MVP Gate)

The MVP checkpoint is **PASSED** when:

1. ✅ Two users can send/receive messages in real-time
2. ✅ Messages persist after app restart
3. ✅ Messages appear instantly with optimistic UI
4. ✅ Offline → online transition works (messages queue and send) *(validated using macOS Network Link Conditioner with 100% packet loss profile)*
5. ✅ Group chat with 3 participants works
6. ✅ Read receipts show correctly
7. ✅ Images can be sent/received (Firebase Storage + Nuke caching)
8. ✅ App handles force quit without losing messages
9. ⚠️ Push notifications simulate foreground experience via local notifications (real APNs delivery pending developer enrollment)
10. ✅ Online/offline status indicators work

**Testing Checklist:**
- [x] Send 20 rapid-fire messages (no lag or loss)
- [x] Enable Network Link Conditioner 100% Loss, send 5 messages, disable (all send)
- [x] Force quit mid-send, reopen app (message sends)
- [x] Background app, receive message (local banner appears)
- [x] Create group, send messages as each of 3 users (all see messages)
- [x] Send image from camera roll (appears in chat)
- [x] Restart app (all message history intact)

---

## Post-MVP: AI Features Roadmap

**Phase 2 (Days 2-4):** Implement 5 required AI features for Busy Parent persona
1. Smart calendar extraction
2. Decision summarization
3. Priority message highlighting
4. RSVP tracking
5. Deadline/reminder extraction

**Phase 3 (Days 5-7):** Implement 1 advanced capability
- Option A: Proactive Assistant (detects conflicts, suggests solutions)
- Option B: Multi-Step Agent (plans activities based on preferences)

**AI Tech Stack (Post-MVP):**
- OpenAI GPT-4 or Anthropic Claude
- Firebase Cloud Functions (serverless AI calls)
- AI SDK by Vercel (function calling)
- Vector database for conversation history (Pinecone or pgvector)

---

## Timeline (24-Hour MVP Sprint)

**Hours 0-2:** Environment setup (Xcode, Firebase project)  
**Hours 2-4:** Basic SwiftUI project + Firebase integration  
**Hours 4-8:** Authentication + user profiles  
**Hours 8-14:** Core 1:1 messaging (80% of effort)  
**Hours 14-18:** Group chat  
**Hours 18-21:** Image support  
**Hours 21-23:** Testing + bug fixes  
**Hour 24:** MVP checkpoint demo  

---

## Final Notes

This PRD is intentionally focused on **infrastructure over features**. The goal is to build a messaging foundation that could scale to billions of users—just like WhatsApp started with two developers.

AI features will transform this into a next-generation messaging app for busy parents, but only after we prove the core experience is bulletproof.

**Remember:** Reliable > Feature-rich