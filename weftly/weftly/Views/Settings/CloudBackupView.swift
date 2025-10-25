//
//  CloudBackupView.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/24/25.
//

import SwiftUI
import SwiftData

struct CloudBackupView: View {
    @ObservedObject var viewModel: CloudBackupViewModel
    @State private var showRestoreAlert = false
    @State private var showRestoreConfirmation = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            // Backup Toggle Section
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.backupEnabled },
                    set: { newValue in
                        Task {
                            await viewModel.toggleBackup(newValue)
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Cloud Backup")
                            .font(.body)
                        Text("Back up your messages to Firebase Storage")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("When enabled, your messages will be backed up to the cloud according to the schedule below. Your data is stored securely and can be restored if you reinstall the app.")
            }
            
            // Backup Schedule Section
            if viewModel.backupEnabled {
                Section {
                    Picker("Backup Schedule", selection: Binding(
                        get: { viewModel.backupSchedule },
                        set: { newValue in
                            Task {
                                await viewModel.updateSchedule(newValue)
                            }
                        }
                    )) {
                        ForEach(BackupSchedule.allCases, id: \.self) { schedule in
                            Text(schedule.displayName).tag(schedule)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Schedule")
                } footer: {
                    if let lastBackup = viewModel.lastBackupAt {
                        Text("Last backup: \(lastBackup.formatted(date: .abbreviated, time: .shortened))")
                    } else {
                        Text("No backups yet")
                    }
                }
            }
            
            // Manual Backup Section
            if viewModel.backupEnabled {
                Section {
                    Button {
                        Task {
                            await viewModel.performBackupNow()
                        }
                    } label: {
                        HStack {
                            if viewModel.isBackingUp {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Backup Now")
                                .foregroundStyle(viewModel.isBackingUp ? Color.secondary : Color.blue)
                        }
                    }
                    .disabled(viewModel.isBackingUp)
                } header: {
                    Text("Manual Backup")
                } footer: {
                    Text("Trigger an immediate backup. Your messages will be uploaded to cloud storage.")
                }
            }
            
            // Restore Section
            Section {
                Button(role: .destructive) {
                    showRestoreAlert = true
                } label: {
                    HStack {
                        if viewModel.isRestoring {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text("Restore from Backup")
                    }
                }
                .disabled(!viewModel.backupExists || viewModel.isRestoring)
            } header: {
                Text("Restore")
            } footer: {
                if viewModel.backupExists {
                    Text("This will DELETE all local chats and replace them with your cloud backup. This action cannot be undone.")
                } else {
                    Text("No backup found in cloud storage.")
                }
            }
            
            // Success/Error Messages
            if let successMessage = viewModel.successMessage {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(successMessage)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Cloud Backup")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .alert("Restore from Backup", isPresented: $showRestoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Continue", role: .destructive) {
                showRestoreConfirmation = true
            }
        } message: {
            Text("This will DELETE all local chats and replace with backup. Continue?")
        }
        .alert("Are You Absolutely Sure?", isPresented: $showRestoreConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                Task {
                    await viewModel.restoreFromBackup()
                }
            }
        } message: {
            Text("Local data will be permanently lost. This cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        CloudBackupView(viewModel: CloudBackupViewModel(authService: AuthService()))
    }
}

