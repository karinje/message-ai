//
//  EditAboutView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI

struct EditAboutView: View {
    @ObservedObject var authService: AuthService
    @State private var aboutText: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    let maxCharacters = 139
    
    var remainingCharacters: Int {
        maxCharacters - aboutText.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Text Editor
                TextEditor(text: $aboutText)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onChange(of: aboutText) { _, newValue in
                        if newValue.count > maxCharacters {
                            aboutText = String(newValue.prefix(maxCharacters))
                        }
                    }
                
                // Character Count
                HStack {
                    Spacer()
                    Text("\(remainingCharacters) / \(maxCharacters)")
                        .font(.caption)
                        .foregroundStyle(remainingCharacters < 0 ? .red : .secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // Error Message
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                    .padding()
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await saveAbout()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving || aboutText.count > maxCharacters)
                }
            }
            .onAppear {
                aboutText = authService.currentUser?.about ?? "Hey there! I am using Weftly."
            }
        }
    }
    
    private func saveAbout() async {
        isSaving = true
        errorMessage = nil
        
        do {
            try await authService.updateAbout(aboutText)
            dismiss()
        } catch {
            print("[EditAboutView] Save failed: \(error.localizedDescription)")
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
}

#Preview {
    EditAboutView(authService: AuthService())
}

