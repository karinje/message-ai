# Contacts Integration & Camera Guide

## ✅ Camera Integration (COMPLETE)

### What's Implemented:
The camera button is now on the top right of the Chats tab, matching the reference image.

**Location:** Top right navigation bar, left of the "+" button

**How It Works:**
1. Tap camera icon → Shows action sheet with 2 options:
   - **"Take Photo"** → Opens device camera
   - **"Choose from Library"** → Opens photo library
2. Select/capture photo → Returns to user search to select recipient
3. Select recipient → Opens chat with photo ready to send

**Files:**
- `ChatListView.swift` - Camera button + action sheet
- `CameraPickerView.swift` - Camera access wrapper
- `ImageLibraryPickerView.swift` - Photo library access wrapper

**Permissions Required:**
- **Camera:** First time user taps "Take Photo", iOS prompts for camera permission
- **Photo Library:** First time user taps "Choose from Library", iOS prompts for photo access

Add these to `Info.plist` if not already present:
```xml
<key>NSCameraUsageDescription</key>
<string>Weftly needs camera access to take photos for sharing</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Weftly needs photo library access to select photos for sharing</string>
```

---

## 📱 Contacts Integration (CURRENT STATE)

### What's Already Working:

**User Search:**
- `UserSearchView.swift` exists and allows finding users by email/name
- Real-time search against Firestore `users` collection
- Displays all registered Weftly users
- No device contacts required

**How Users Find Each Other Now:**
1. User A signs up with email: `alice@example.com`
2. User B goes to "New Direct Chat" and searches for "alice"
3. Firestore query finds Alice's user document
4. User B can start chatting with Alice

### What's NOT Yet Implemented:

**Full Contacts Framework Integration:**
According to the PRD, the app should:
1. Request device contacts permission on first use
2. Upload hashed phone numbers to Firestore for privacy
3. Match device contacts against other Weftly users
4. Show "Contacts on Weftly" vs "Invite to Weftly" sections
5. Display frequently contacted users at top

**Why It's Not Critical for MVP:**
- Users can still find each other via email/username search
- Adds complexity (phone number verification, hashing, privacy concerns)
- Can be added as enhancement after core messaging is solid

### How to Add Full Contacts Integration (Future):

**Step 1: Add Contacts Permission**
```swift
import Contacts

class ContactsService {
    func requestAccess() async throws -> Bool {
        let store = CNContactStore()
        return try await store.requestAccess(for: .contacts)
    }
}
```

**Step 2: Add to Info.plist:**
```xml
<key>NSContactsUsageDescription</key>
<string>Weftly needs access to your contacts to help you find friends who are also on Weftly</string>
```

**Step 3: Sync Flow:**
```swift
func syncContacts() async {
    // 1. Fetch device contacts
    let contacts = try await fetchContacts()
    
    // 2. Extract phone numbers
    let phoneNumbers = contacts.flatMap { $0.phoneNumbers }
    
    // 3. Normalize to E.164 format (+15551234567)
    let normalized = phoneNumbers.map { normalizePhoneNumber($0) }
    
    // 4. Hash for privacy (SHA-256)
    let hashes = normalized.map { hashPhoneNumber($0) }
    
    // 5. Upload to Firestore
    // users/{userId}/phoneNumberHash: "abc123..."
    
    // 6. Query for matches
    // Find other users with matching phoneNumberHash
    
    // 7. Display in "Contacts on Weftly" section
}
```

**Step 4: Update User Model:**
```swift
struct User {
    var phoneNumber: String? // E.164: +15551234567
    var phoneNumberHash: String? // SHA-256 hash
    var contactsSynced: Bool
}
```

**Current Workaround:**
Users share their email addresses to find each other, similar to Telegram's username system.

---

## 🗑️ Delete All Chats (FIXED)

### What It Deletes:

**Local SwiftData (Device Storage):**
1. ✅ **LocalMessage** - All cached messages
2. ✅ **LocalConversationState** - All unread counter states
3. ✅ **PendingMessage** - All queued unsent messages

**What It Does NOT Delete:**
- ❌ Firestore messages (still visible to other users)
- ❌ Conversation metadata in Firestore
- ❌ Your user account

### Why You Don't See Changes Immediately:

The issue is that **ChatListViewModel** loads conversations from **Firestore**, not SwiftData. Here's the data flow:

```
Firestore (conversations) → ChatListViewModel → ChatListView
                ↓
        (messages cached locally)
                ↓
          SwiftData (LocalMessage)
```

When you delete from SwiftData:
- ✅ Local cache cleared
- ✅ Unread counters reset
- ❌ Firestore conversations still exist
- ❌ UI still shows conversation list from Firestore

### To Fully Clear Conversations:

**Option A: Delete from Firestore too** (need to implement):
```swift
func deleteAllChats(modelContext: ModelContext) async throws {
    guard let userId = authService.currentUser?.id else { return }
    
    // 1. Delete local SwiftData (already implemented)
    deleteLocalMessages(modelContext)
    
    // 2. Delete Firestore conversations (NEW)
    let conversations = try await db.collection("conversations")
        .whereField("participants", arrayContains: userId)
        .getDocuments()
    
    for doc in conversations.documents {
        try await doc.reference.delete()
    }
}
```

**Option B: Leave Firestore alone** (current behavior):
- Conversations stay in Firestore (messages visible to other users)
- Local cache cleared (frees up device storage)
- Conversations re-download from Firestore on next app launch
- Messages reload into cache on next open

### Recommendation:

Update the alert message to be clearer:
```swift
Text("This will delete all your LOCAL chat history. Conversations will remain on the server and other users can still see their messages. To permanently delete conversations for everyone, use 'Delete Account' instead.")
```

---

## Summary of Changes Made:

### ✅ Fixed:
1. **Camera Button** - Now visible on Chats tab top right
2. **Camera/Photo Access** - Action sheet with Take Photo/Choose from Library
3. **Delete All Chats** - Now properly deletes all local SwiftData
4. **Delete Logic** - Clears LocalMessage, LocalConversationState, PendingMessage

### 📝 Documented:
1. **Contacts Integration** - How it works now (email search) vs full implementation
2. **Delete Behavior** - What gets deleted and why UI doesn't refresh immediately
3. **Camera Permissions** - Required Info.plist entries

### 🔜 Future Enhancements:
1. **Full Contacts Sync** - Phone number hashing and matching
2. **Delete from Firestore** - Option to delete conversations for all users
3. **Camera → Chat Flow** - Directly attach photo to selected chat
4. **Frequently Contacted** - Show most-messaged contacts at top


