//
//  ContentView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isAuthenticated = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                ChatListView(authService: authService)
            } else {
                LoginView(isAuthenticated: $isAuthenticated)
            }
        }
        .onChange(of: isAuthenticated) { _, newValue in
            authService.isAuthenticated = newValue
        }
        .onChange(of: authService.isAuthenticated) { _, newValue in
            isAuthenticated = newValue
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
