//
//  MainTabView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var authService: AuthService
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var selectedTab = 1 // Start on Chats tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1 (leftmost): Assistant - AI Chat
            AssistantChatView()
                .tabItem {
                    Label("Assistant", systemImage: "sparkles")
                }
                .tag(0)
            
            // Tab 2: Digest - AI-extracted insights
            DigestView(authService: authService)
                .tabItem {
                    Label("Digest", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(1)
            
            // Tab 3: Chats (main messaging tab)
            ChatListView(authService: authService, networkMonitor: networkMonitor)
                .tabItem {
                    Label("Chats", systemImage: "message")
                }
                .tag(2)
            
            // Tab 4 (rightmost): Settings
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

