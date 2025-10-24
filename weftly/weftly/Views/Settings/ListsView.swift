//
//  ListsView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI

struct ListsView: View {
    @ObservedObject var viewModel: ListsViewModel
    @State private var showCreateList = false
    
    var body: some View {
        List {
            // Top card with explanation
            Section {
                VStack(spacing: 16) {
                    // Icon illustration
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.title2)
                        Image(systemName: "briefcase.fill")
                            .foregroundStyle(.blue)
                            .font(.title2)
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title2)
                    }
                    .padding(.top, 8)
                    
                    Text("Any list you create becomes a filter at the top of your Chats tab.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showCreateList = true
                    } label: {
                        Label("Create a custom list", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            // Your Lists Section
            Section {
                // Preset lists
                ForEach(viewModel.presetLists) { list in
                    ListRow(list: list, viewModel: viewModel)
                }
                
                // Custom lists
                ForEach(viewModel.customLists) { list in
                    ListRow(list: list, viewModel: viewModel)
                }
            } header: {
                Text("Your Lists")
            }
        }
        .navigationTitle("Lists")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCreateList) {
            CreateListView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
}

struct ListRow: View {
    let list: ConversationList
    @ObservedObject var viewModel: ListsViewModel
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack {
            if let icon = list.icon {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .frame(width: 30)
            }
            
            Text(list.name)
            
            Spacer()
            
            if !list.isPreset {
                Menu {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete List", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .alert("Delete List", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let listId = list.id {
                    Task {
                        try? await viewModel.deleteList(listId: listId)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(list.name)\"?")
        }
    }
}

#Preview {
    NavigationStack {
        ListsView(viewModel: ListsViewModel(authService: AuthService()))
    }
}

