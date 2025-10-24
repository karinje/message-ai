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
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
        }
    }
    
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        print("🔄 Scene phase changed: \(oldPhase) → \(newPhase)")
        
        switch newPhase {
        case .active:
            // App became active - update presence to online
            Task {
                await authService.updatePresence(isOnline: true)
            }
        case .inactive:
            // App going to background or being terminated - update presence
            break
        case .background:
            // App in background - mark as offline
            Task {
                await authService.updatePresence(isOnline: false)
            }
        @unknown default:
            break
        }
    }
}
