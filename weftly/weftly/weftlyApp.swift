//
//  weftlyApp.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI
import SwiftData
import Nuke

@main
struct weftlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authService = AuthService()
    @Environment(\.scenePhase) private var scenePhase
    
    let modelContainer: ModelContainer
    
    init() {
        // Configure Nuke for aggressive caching
        DataLoader.sharedUrlCache.diskCapacity = 200 * 1024 * 1024
        ImageCache.shared.costLimit = 100 * 1024 * 1024
        ImageCache.shared.countLimit = 200
        
        let schema = Schema([
            PendingMessage.self,
            LocalMessage.self,
            LocalConversationState.self,
            ExtractedEvent.self,
            Deadline.self
        ])
        
        do {
            // Try with default URL first
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                url: url,
                allowsSave: true
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            print("✅ ModelContainer initialized successfully")
        } catch {
            print("❌ Failed to initialize ModelContainer: \(error)")
            print("🗑️ Attempting to delete old store and recreate...")
            
            // Delete old store files
            do {
                let fileManager = FileManager.default
                let appSupport = URL.applicationSupportDirectory
                
                // Delete all .store files
                if let contents = try? fileManager.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil) {
                    for file in contents where file.pathExtension == "store" || file.lastPathComponent.contains("default") {
                        try? fileManager.removeItem(at: file)
                        print("🗑️ Deleted: \(file.lastPathComponent)")
                    }
                }
                
                // Recreate with fresh store
                let url = URL.applicationSupportDirectory.appending(path: "default.store")
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    url: url,
                    allowsSave: true
                )
                
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
                print("✅ ModelContainer recreated successfully with fresh store")
            } catch {
                fatalError("Failed to initialize ModelContainer even after cleanup: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .modelContainer(modelContainer)
                .task {
                    NotificationService.shared.configure(authService: authService)
                    // Set initial online presence when app launches
                    if authService.isAuthenticated {
                        await authService.updatePresence(isOnline: true)
                    }
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
        }
        .onChange(of: authService.isAuthenticated) { oldValue, newValue in
            // Update presence when auth state changes
            if newValue {
                Task {
                    await authService.updatePresence(isOnline: true)
                }
            }
        }
    }
    
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        print("🔄 Scene phase changed: \(oldPhase) → \(newPhase)")
        
        // Only update if user is authenticated
        guard authService.isAuthenticated else {
            print("⚠️ Skipping presence update - user not authenticated")
            return
        }
        
        switch newPhase {
        case .active:
            // App became active - update presence to online
            print("✅ Setting presence to ONLINE (app active)")
            Task {
                await authService.updatePresence(isOnline: true)
            }
        case .inactive:
            // App going to background or being terminated - update presence
            print("⏸️ App inactive - keeping current presence")
            break
        case .background:
            // App in background - mark as offline
            print("❌ Setting presence to OFFLINE (app background)")
            Task {
                await authService.updatePresence(isOnline: false)
            }
        @unknown default:
            break
        }
    }
}
