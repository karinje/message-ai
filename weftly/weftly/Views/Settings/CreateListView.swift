//
//  CreateListView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI

struct CreateListView: View {
    @ObservedObject var viewModel: ListsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var listName = ""
    @State private var selectedIcon: String = "list.bullet"
    @State private var selectedConversations: Set<String> = []
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Common SF Symbols for lists
    let availableIcons = [
        "list.bullet", "star.fill", "heart.fill", "briefcase.fill",
        "house.fill", "person.2.fill", "gamecontroller.fill", "cart.fill",
        "book.fill", "flag.fill", "tag.fill", "folder.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("List Name", text: $listName)
                } header: {
                    Text("Name")
                }
                
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon ? .white : .blue)
                                    .frame(width: 60, height: 60)
                                    .background(selectedIcon == icon ? Color.blue : Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Icon")
                }
                
                Section {
                    Text("After creating your list, you can add conversations to it from the chat list.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Note")
                }
            }
            .navigationTitle("Create List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createList()
                    }
                    .disabled(listName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createList() {
        Task {
            do {
                try await viewModel.createList(
                    name: listName,
                    conversationIds: [],
                    icon: selectedIcon
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    CreateListView(viewModel: ListsViewModel(authService: AuthService()))
}

