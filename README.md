# Weftly

A real-time messaging app for busy parents and caregivers with AI-powered insights.

**App Name:** Weftly  
**Bundle ID:** com.sanjaykarinje.weftly  
**Firebase Project:** Weftly  

## Project Status
✅ **MVP Complete** – Core messaging experience implemented  
✅ **AI Features (Phase 1)** – Calendar extraction, priority detection, and deadline tracking live

## Tech Stack
- **Platform:** iOS 17.0+
- **Language:** Swift 5.10+
- **UI:** SwiftUI
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Messaging, Cloud Functions)
- **AI:** OpenAI GPT-4o-mini (extraction), GPT-4o (chat)
- **Local Storage:** SwiftData
- **Image Pipeline:** Nuke/NukeUI for caching & progressive loading

## Setup
1. Install Xcode 16.x
2. Clone this repository
3. Add your `GoogleService-Info.plist` to `weftly/weftly/`
4. Configure Firebase Functions with OpenAI API key
5. Open `Weftly.xcodeproj`
6. Build & run (iPhone 17 Pro simulator recommended)

## Key Features

### Core Messaging (MVP)
- **Authentication & Profiles** – Firebase email/password auth, display names, avatar support
- **1:1 & Group Messaging** – Real-time delivery with optimistic UI, roster header for groups
- **Message States** – Sending → Sent → Delivered → Read with double-check visuals
- **Presence & Typing Indicators** – Online status and live typing feedback
- **Offline Resilience** – SwiftData-backed message queue; validated via macOS Network Link Conditioner (100% packet-loss profile)
- **Image Sharing** – Firebase Storage uploads with Nuke disk/memory caching, optional captions
- **Push Notifications** – APNs/FCM delivery on devices; simulator mirrors banners locally while app is foregrounded
- **Custom Branding** – Weftly app icon and color palette

### AI-Powered Insights (Phase 1)
- **📅 Calendar Extraction** – Automatically detects meetings, appointments, and events from messages
  - Timezone-aware (Pacific Time)
  - One-tap "Add to Calendar" integration
  - Dismissible cards for irrelevant events
  
- **🚨 Priority Detection** – Flags urgent and important messages
  - Real-time analysis of message content
  - Urgent/Important classification with AI reasoning
  - Quick navigation to priority conversations
  
- **⏰ Deadline Tracking** – Extracts action items with due dates
  - Automatic deadline detection from natural language
  - Organized by timeframe (Overdue, Today, This Week, Later)
  - Dismissible tasks once completed

- **📊 Digest Tab** – Unified AI insights dashboard
  - Auto-refreshes every 30 seconds
  - Pull-to-refresh for manual updates
  - Persistent dismissal system (dismissed items don't reappear)

## Push Notification Note
- Physical devices: app registers with APNs, stores the FCM token, and the Cloud Function `onMessageCreated` sends pushes via FCM → APNs.
- Simulator: `NotificationService` swaps to a debug presenter that mirrors banners using local notifications (foreground only).
- To enable real APNs delivery on device: enroll in Apple Developer Program, upload the APNs auth key to Firebase Cloud Messaging, and run on hardware.

## Documentation
- [Product Requirements Document](docs/messageai_prd.md)
- [Architecture Diagram](docs/messageai_architecture_diagram.mermaid)
- [Task Breakdown](docs/messageai_tasks.md)
- [AI Implementation Plan](docs/weftly_ai_implementation_plan_comprehensive.md)
- [Contacts & Camera Guide](docs/CONTACTS_AND_CAMERA_GUIDE.md)

## Next Steps (Phase 2)
- RSVP Tracking (group event responses)
- Decision Summarization (consensus detection)
- AI Chat Agent (conversational assistant)
- Configure APNs credentials for real push delivery

## Credits
Built by Sanjay Karinje – October 2025
