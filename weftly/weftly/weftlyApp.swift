//
//  weftlyApp.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI
import FirebaseCore
import SwiftData

@main
struct weftlyApp: App {
    @StateObject private var authService = AuthService()
    
    let modelContainer: ModelContainer
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Initialize SwiftData
        do {
            modelContainer = try ModelContainer(for: PendingMessage.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .modelContainer(modelContainer)
        }
    }
}
