//
//  BroadcastView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI

struct BroadcastView: View {
    @ObservedObject var viewModel: BroadcastViewModel
    @State private var showCreateBroadcastList = false
    
    var body: some View {
        ZStack {
            if viewModel.broadcastLists.isEmpty {
                // Empty State
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "megaphone")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("You should use broadcast lists to message multiple people at once")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    Button {
                        showCreateBroadcastList = true
                    } label: {
                        Label("New List", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            } else {
                // List of broadcast lists
                List {
                    ForEach(viewModel.broadcastLists) { broadcastList in
                        NavigationLink {
                            BroadcastListDetailView(
                                viewModel: viewModel,
                                broadcastList: broadcastList
                            )
                        } label: {
                            BroadcastListRow(broadcastList: broadcastList)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let list = viewModel.broadcastLists[index]
                            if let listId = list.id {
                                Task {
                                    try? await viewModel.deleteBroadcastList(listId: listId)
                                }
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showCreateBroadcastList = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
            }
        }
        .navigationTitle("Broadcast Lists")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCreateBroadcastList) {
            CreateBroadcastListView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
}

struct BroadcastListRow: View {
    let broadcastList: BroadcastList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(broadcastList.name)
                .font(.headline)
            
            Text("\(broadcastList.recipientIds.count) recipients")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if broadcastList.messageCount > 0 {
                Text("\(broadcastList.messageCount) messages sent")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        BroadcastView(viewModel: BroadcastViewModel(authService: AuthService()))
    }
}

