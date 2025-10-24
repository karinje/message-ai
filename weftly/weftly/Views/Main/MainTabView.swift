//
//  MainTabView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var authService: AuthService
    @State private var selectedTab = 1 // Start on Chats tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 4 (leftmost): AI
            AIView()
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }
                .tag(0)
            
            // Tab 3: Updates
            UpdatesView()
                .tabItem {
                    Label("Updates", systemImage: "circle.circle")
                }
                .tag(1)
            
            // Tab 2: Chats (main tab)
            ChatListView(authService: authService)
                .tabItem {
                    Label("Chats", systemImage: "message")
                }
                .tag(2)
            
            // Tab 1 (rightmost): Settings
            SettingsView(authService: authService)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .tint(.green) // WhatsApp-style green accent
    }
}

#Preview {
    MainTabView(authService: AuthService())
}

