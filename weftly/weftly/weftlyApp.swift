//
//  weftlyApp.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI
import SwiftData

@main
struct weftlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authService = AuthService()
    @Environment(\.scenePhase) private var scenePhase
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: PendingMessage.self)
        } catch {
            fatalError("Failed to initialize ModelContainecuchr: \(error)")
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
