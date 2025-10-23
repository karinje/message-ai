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
    }
}
