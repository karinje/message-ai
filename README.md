# Weftly

A real-time messaging app for busy parents and caregivers.

**App Name:** Weftly  
**Bundle ID:** com.sanjaykarinje.weftly  
**Firebase Project:** Weftly  

## Project Status
✅ **MVP Complete** – Core messaging experience implemented

## Tech Stack
- **Platform:** iOS 17.0+
- **Language:** Swift 5.10+
- **UI:** SwiftUI
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Messaging)
- **Local Storage:** SwiftData
- **Image Pipeline:** Nuke/NukeUI for caching & progressive loading

## Setup
1. Install Xcode 16.x
2. Clone this repository
3. Add your `GoogleService-Info.plist` to `weftly/weftly/`
4. Open `Weftly.xcodeproj`
5. Build & run (iPhone 17 Pro simulator recommended)

## Key MVP Features
- **Authentication & Profiles** – Firebase email/password auth, display names, avatar support
- **1:1 & Group Messaging** – Real-time delivery with optimistic UI, roster header for groups
- **Message States** – Sending → Sent → Delivered → Read with double-check visuals
- **Presence & Typing Indicators** – Online status and live typing feedback
- **Offline Resilience** – SwiftData-backed message queue; validated via macOS Network Link Conditioner (100% packet-loss profile)
- **Image Sharing** – Firebase Storage uploads with Nuke disk/memory caching, optional captions
- **Push Notifications** – APNs/FCM delivery on devices; simulator mirrors banners locally while app is foregrounded
- **Custom Branding** – Weftly app icon and color palette

## Push Notification Note
- Physical devices: app registers with APNs, stores the FCM token, and the Cloud Function `onMessageCreated` sends pushes via FCM → APNs.
- Simulator: `NotificationService` swaps to a debug presenter that mirrors banners using local notifications (foreground only).
- To enable real APNs delivery on device: enroll in Apple Developer Program, upload the APNs auth key to Firebase Cloud Messaging, and run on hardware.

## Documentation
- [Product Requirements Document](messageai_prd.md)
- [Architecture Diagram](messageai_architecture_diagram.mermaid)
- [Task Breakdown](messageai_tasks.md)

## Next Steps (Post-MVP)
- Configure APNs credentials for real push delivery
- Begin AI feature phase (calendar extraction, decision summaries, etc.)

## Credits
Built by Sanjay Karinje – October 2025

