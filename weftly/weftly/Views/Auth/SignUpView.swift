//
//  SignUpView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService()
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Join Weftly")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Form
                VStack(spacing: 16) {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    Button(action: signUp) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
                    .disabled(!isFormValid || isLoading)
                    
                    Button("Already have an account? Log in") {
                        dismiss()
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !displayName.isEmpty && password == confirmPassword && password.count >= 6
    }
    
    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await authService.signUp(email: email, password: password, displayName: displayName)
                isAuthenticated = true
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

