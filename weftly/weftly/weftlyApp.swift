//
//  weftlyApp.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI
import FirebaseCore
import SwiftData
import FirebaseMessaging

@main
struct weftlyApp: App {
    @StateObject private var authService = AuthService()
    
    let modelContainer: ModelContainer
    
    init() {
        FirebaseApp.configure()
        do {
            modelContainer = try ModelContainer(for: PendingMessage.self)
        } catch {
            fatalError("Failed to initialize ModelContainecuchr: \(error)")
        }
        Messaging.messaging().delegate = NotificationDelegate.shared
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .modelContainer(modelContainer)
                .task {
                    NotificationService.shared.configure(authService: authService)
                    NotificationService.shared.requestAuthorizationIfNeeded()
                }
        }
    }
}
