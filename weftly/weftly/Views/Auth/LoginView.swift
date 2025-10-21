//
//  LoginView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false
    
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Logo
                Image(systemName: "message.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                Text("Weftly")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Connect with your family")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text("Log In")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .background(email.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    
                    Button("Don't have an account? Sign up") {
                        showSignUp = true
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView(isAuthenticated: $isAuthenticated)
            }
        }
    }
    
    private func login() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await authService.signIn(email: email, password: password)
                isAuthenticated = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

