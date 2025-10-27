//
//  DigestService.swift
//  weftly
//
//  Created for unified agent architecture (PR #31)
//  Syncs digest items from Firestore to SwiftData

import Foundation
import FirebaseFirestore
import SwiftData
import Combine

@MainActor
class DigestService: ObservableObject {
    static let shared = DigestService()
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    private init() {}
    
    // Start listening to all digest subcollections
    func startListening(userId: String, context: ModelContext) {
        stopListening()
        
        // Listen to events
        let eventsListener = db.collection("users").document(userId)
            .collection("digest").document("events")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard
                    let self,
                    let snapshot,
                    error == nil
                else {
                    if let error {
                        print("❌ Events listener error: \(error.localizedDescription)")
                    }
                    return
                }
                self.syncEvents(changes: snapshot.documentChanges, context: context, sourceCount: snapshot.documents.count)
            }
        
        // Listen to deadlines
        let deadlinesListener = db.collection("users").document(userId)
            .collection("digest").document("deadlines")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard
                    let self,
                    let snapshot,
                    error == nil
                else {
                    if let error {
                        print("❌ Deadlines listener error: \(error.localizedDescription)")
                    }
                    return
                }
                self.syncDeadlines(changes: snapshot.documentChanges, context: context, sourceCount: snapshot.documents.count)
            }
        
        // Listen to priority messages
        let priorityListener = db.collection("users").document(userId)
            .collection("digest").document("priorityMessages")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard
                    let self,
                    let snapshot,
                    error == nil
                else {
                    if let error {
                        print("❌ Priority listener error: \(error.localizedDescription)")
                    }
                    return
                }
                self.syncPriorityMessages(changes: snapshot.documentChanges, context: context, sourceCount: snapshot.documents.count)
            }
        
        // Listen to RSVPs
        let rsvpsListener = db.collection("users").document(userId)
            .collection("digest").document("rsvps")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard
                    let self,
                    let snapshot,
                    error == nil
                else {
                    if let error {
                        print("❌ RSVPs listener error: \(error.localizedDescription)")
                    } else {
                        print("⚠️ RSVPs listener: snapshot nil")
                    }
                    return
                }
                self.syncRSVPs(changes: snapshot.documentChanges, context: context, sourceCount: snapshot.documents.count)
            }
        
        // Listen to suggestions
        let suggestionsListener = db.collection("users").document(userId)
            .collection("digest").document("suggestions")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard
                    let self,
                    let snapshot,
                    error == nil
                else {
                    if let error {
                        print("❌ Suggestions listener error: \(error.localizedDescription)")
                    }
                    return
                }
                self.syncSuggestions(changes: snapshot.documentChanges, context: context, sourceCount: snapshot.documents.count)
            }
        
        listeners = [eventsListener, deadlinesListener, priorityListener, rsvpsListener, suggestionsListener]
    }
    
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Sync Methods
    
    private func syncEvents(changes: [DocumentChange], context: ModelContext, sourceCount: Int) {
        guard !changes.isEmpty else { return }
        var didMutate = false
        for change in changes {
            let doc = change.document
            let id = doc.documentID
            let data = doc.data()
            let descriptor = FetchDescriptor<DigestEvent>(
                predicate: #Predicate { $0.id == id }
            )
            let existing = try? context.fetch(descriptor).first
            switch change.type {
            case .added, .modified:
                let target = existing ?? DigestEvent(
                    id: id,
                    title: data["title"] as? String ?? "",
                    date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                    conversationId: data["conversationId"] as? String ?? "",
                    messageId: data["messageId"] as? String ?? "",
                    time: data["time"] as? String,
                    location: data["location"] as? String,
                    confidence: data["confidence"] as? Double ?? 0.0
                )
                target.title = data["title"] as? String ?? target.title
                target.date = (data["date"] as? Timestamp)?.dateValue() ?? target.date
                target.time = data["time"] as? String
                target.location = data["location"] as? String
                target.confidence = data["confidence"] as? Double ?? target.confidence
                target.status = data["status"] as? String ?? target.status
                target.addedToCalendar = data["addedToCalendar"] as? Bool ?? target.addedToCalendar
                target.lastMentionedAt = (data["lastMentionedAt"] as? Timestamp)?.dateValue() ?? target.lastMentionedAt
                if existing == nil {
                    context.insert(target)
                    print("✨ Event created: \(target.title)")
                }
                didMutate = true
            case .removed:
                if let event = existing {
                    context.delete(event)
                    didMutate = true
                }
            @unknown default:
                break
            }
        }
        if didMutate {
            do {
                try context.save()
            } catch {
                print("❌ Failed to save events: \(error)")
            }
        }
    }
    
    private func syncDeadlines(changes: [DocumentChange], context: ModelContext, sourceCount: Int) {
        guard !changes.isEmpty else { return }
        var didMutate = false
        for change in changes {
            let doc = change.document
            let data = doc.data()
            let id = doc.documentID
            let descriptor = FetchDescriptor<DigestDeadline>(
                predicate: #Predicate { $0.id == id }
            )
            let existing = try? context.fetch(descriptor).first
            switch change.type {
            case .added, .modified:
                let target = existing ?? DigestDeadline(
                    id: id,
                    task: data["task"] as? String ?? "",
                    dueDate: (data["dueDate"] as? Timestamp)?.dateValue() ?? Date(),
                    assignedTo: data["assignedTo"] as? String ?? "",
                    conversationId: data["conversationId"] as? String ?? "",
                    messageId: data["messageId"] as? String ?? "",
                    priority: data["priority"] as? String ?? "medium",
                    confidence: data["confidence"] as? Double ?? 0.0
                )
                target.task = data["task"] as? String ?? target.task
                target.dueDate = (data["dueDate"] as? Timestamp)?.dateValue() ?? target.dueDate
                target.priority = data["priority"] as? String ?? target.priority
                target.status = data["status"] as? String ?? target.status
                target.completed = data["completed"] as? Bool ?? target.completed
                if existing == nil {
                    context.insert(target)
                    print("✨ Deadline created: \(target.task)")
                }
                didMutate = true
            case .removed:
                if let deadline = existing {
                    context.delete(deadline)
                    didMutate = true
                }
            @unknown default:
                break
            }
        }
        if didMutate {
            do {
                try context.save()
            } catch {
                print("❌ Failed to save deadlines: \(error)")
            }
        }
    }
    
    private func syncPriorityMessages(changes: [DocumentChange], context: ModelContext, sourceCount: Int) {
        guard !changes.isEmpty else { return }
        var didMutate = false
        for change in changes {
            let doc = change.document
            let data = doc.data()
            let id = doc.documentID
            let descriptor = FetchDescriptor<DigestPriorityMessage>(
                predicate: #Predicate { $0.id == id }
            )
            let existing = try? context.fetch(descriptor).first
            switch change.type {
            case .added, .modified:
                let target = existing ?? DigestPriorityMessage(
                    id: id,
                    messageText: data["messageText"] as? String ?? "",
                    priority: data["priority"] as? String ?? "important",
                    reason: data["reason"] as? String ?? "",
                    conversationId: data["conversationId"] as? String ?? "",
                    senderId: data["senderId"] as? String ?? "",
                    senderName: data["senderName"] as? String ?? "",
                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                    requiresAction: data["requiresAction"] as? Bool ?? false
                )
                target.status = data["status"] as? String ?? target.status
                target.messageText = data["messageText"] as? String ?? target.messageText
                target.priority = data["priority"] as? String ?? target.priority
                target.reason = data["reason"] as? String ?? target.reason
                target.senderId = data["senderId"] as? String ?? target.senderId
                target.senderName = data["senderName"] as? String ?? target.senderName
                target.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? target.timestamp
                target.requiresAction = data["requiresAction"] as? Bool ?? target.requiresAction
                if existing == nil {
                    context.insert(target)
                    print("✨ Priority message: \(target.priority) - \(target.messageText.prefix(50))...")
                }
                didMutate = true
            case .removed:
                if let message = existing {
                    context.delete(message)
                    didMutate = true
                }
            @unknown default:
                break
            }
        }
        if didMutate {
            do {
                try context.save()
            } catch {
                print("❌ Failed to save priority messages: \(error)")
            }
        }
    }
    
    private func syncRSVPs(changes: [DocumentChange], context: ModelContext, sourceCount: Int) {
        guard !changes.isEmpty else { return }
        var didMutate = false
        for change in changes {
            let doc = change.document
            let data = doc.data()
            let id = doc.documentID
            let descriptor = FetchDescriptor<DigestRSVP>(
                predicate: #Predicate { $0.id == id }
            )
            let existing = try? context.fetch(descriptor).first
            switch change.type {
            case .added, .modified:
                let target = existing ?? DigestRSVP(
                    id: id,
                    eventId: data["eventId"] as? String ?? "",
                    eventTitle: data["eventTitle"] as? String ?? "",
                    eventDate: (data["eventDate"] as? Timestamp)?.dateValue() ?? Date(),
                    conversationId: data["conversationId"] as? String ?? "",
                    messageId: data["messageId"] as? String ?? "",
                    isHost: data["isHost"] as? Bool ?? false
                )
                let newResponses = data["responsesJSON"] as? String ?? target.responsesJSON
                target.status = data["status"] as? String ?? "pending"
                target.responsesJSON = newResponses
                target.totalInvited = data["totalInvited"] as? Int ?? target.totalInvited
                target.lastUpdated = Date()
                if existing == nil {
                    context.insert(target)
                    print("✨ RSVP created: \(target.eventTitle)")
                }
                didMutate = true
            case .removed:
                if let rsvp = existing {
                    context.delete(rsvp)
                    didMutate = true
                }
            @unknown default:
                break
            }
        }
        if didMutate {
            do {
                try context.save()
            } catch {
                print("❌ Error saving RSVP context: \(error)")
            }
        }
    }
    
    private func syncSuggestions(changes: [DocumentChange], context: ModelContext, sourceCount: Int) {
        guard !changes.isEmpty else { return }
        var didMutate = false
        for change in changes {
            let doc = change.document
            let data = doc.data()
            let id = doc.documentID
            let descriptor = FetchDescriptor<DigestSuggestion>(
                predicate: #Predicate { $0.id == id }
            )
            let existing = try? context.fetch(descriptor).first
            switch change.type {
            case .added, .modified:
                let target = existing ?? DigestSuggestion(
                    id: id,
                    type: data["type"] as? String ?? "proactive",
                    priority: data["priority"] as? String ?? "medium",
                    description: data["suggestionDescription"] as? String ?? ""
                )
                target.status = data["status"] as? String ?? target.status
                target.type = data["type"] as? String ?? target.type
                target.priority = data["priority"] as? String ?? target.priority
                target.suggestionDescription = data["suggestionDescription"] as? String ?? target.suggestionDescription
                
                let optionsJSONFromFirestore = data["optionsJSON"] as? String ?? "[]"
                target.optionsJSON = optionsJSONFromFirestore
                
                let statusFromFirestore = data["status"] as? String ?? "pending"
                
                if existing == nil {
                    print("✨ Suggestion: \(target.suggestionDescription.prefix(50))...")
                    print("   status from Firestore: \(statusFromFirestore)")
                    print("   optionsJSON from Firestore: \(optionsJSONFromFirestore)")
                    print("   Parsed options count: \(target.options.count)")
                    if !target.options.isEmpty {
                        print("   Options: \(target.options)")
                    }
                    context.insert(target)
                } else {
                    print("🔄 Updating existing suggestion: \(target.suggestionDescription.prefix(50))...")
                    print("   OLD status: \(existing!.status) → NEW status: \(statusFromFirestore)")
                }
                didMutate = true
            case .removed:
                if let suggestion = existing {
                    context.delete(suggestion)
                    didMutate = true
                }
            @unknown default:
                break
            }
        }
        if didMutate {
            do {
                try context.save()
            } catch {
                print("❌ Failed to save suggestions: \(error)")
            }
        }
    }
    
    // MARK: - Actions
    
    func acceptEvent(_ eventId: String, userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("digest").document("events")
            .collection("items").document(eventId)
            .updateData(["status": "accepted"])
    }
    
    func dismissEvent(_ eventId: String, userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("digest").document("events")
            .collection("items").document(eventId)
            .updateData(["status": "dismissed"])
    }
    
    func dismissPriorityMessage(_ messageId: String, userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("digest").document("priorityMessages")
            .collection("items").document(messageId)
            .updateData(["status": "dismissed"])
    }
    
    func dismissDeadline(_ deadlineId: String, userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("digest").document("deadlines")
            .collection("items").document(deadlineId)
            .updateData(["status": "dismissed"])
    }
    
    func completeDeadline(_ deadlineId: String, userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("digest").document("deadlines")
            .collection("items").document(deadlineId)
            .updateData([
                "status": "completed",
                "completed": true
            ])
    }
    
    func dismissRSVP(_ rsvpId: String, userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("digest").document("rsvps")
            .collection("items").document(rsvpId)
            .updateData(["status": "dismissed"])
    }
    
    func dismissSuggestion(_ suggestionId: String, userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("digest").document("suggestions")
            .collection("items").document(suggestionId)
            .updateData(["status": "dismissed"])
    }
}

