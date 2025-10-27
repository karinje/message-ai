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
        
        print("👂 Starting digest listeners for user \(userId)")
        
        // Listen to events
        let eventsListener = db.collection("users").document(userId)
            .collection("digest").document("events")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.syncEvents(documents, context: context)
            }
        
        // Listen to deadlines
        let deadlinesListener = db.collection("users").document(userId)
            .collection("digest").document("deadlines")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.syncDeadlines(documents, context: context)
            }
        
        // Listen to priority messages
        let priorityListener = db.collection("users").document(userId)
            .collection("digest").document("priorityMessages")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.syncPriorityMessages(documents, context: context)
            }
        
        // Listen to RSVPs
        let rsvpsListener = db.collection("users").document(userId)
            .collection("digest").document("rsvps")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("⚠️ RSVPs listener: no documents")
                    return
                }
                print("🔔 RSVPs listener fired with \(documents.count) documents")
                self?.syncRSVPs(documents, context: context)
            }
        
        // Listen to suggestions
        let suggestionsListener = db.collection("users").document(userId)
            .collection("digest").document("suggestions")
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.syncSuggestions(documents, context: context)
            }
        
        listeners = [eventsListener, deadlinesListener, priorityListener, rsvpsListener, suggestionsListener]
    }
    
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Sync Methods
    
    private func syncEvents(_ documents: [QueryDocumentSnapshot], context: ModelContext) {
        for doc in documents {
            let data = doc.data()
            let id = doc.documentID
            
            // Check if exists
            let descriptor = FetchDescriptor<DigestEvent>(
                predicate: #Predicate { $0.id == id }
            )
            
            let existingEvent = try? context.fetch(descriptor).first
            
            if let event = existingEvent {
                // Update
                event.title = data["title"] as? String ?? event.title
                event.date = (data["date"] as? Timestamp)?.dateValue() ?? event.date
                event.time = data["time"] as? String
                event.location = data["location"] as? String
                event.confidence = data["confidence"] as? Double ?? event.confidence
                event.status = data["status"] as? String ?? event.status
                event.addedToCalendar = data["addedToCalendar"] as? Bool ?? event.addedToCalendar
                event.lastMentionedAt = (data["lastMentionedAt"] as? Timestamp)?.dateValue() ?? event.lastMentionedAt
            } else {
                // Create
                let newEvent = DigestEvent(
                    id: id,
                    title: data["title"] as? String ?? "",
                    date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                    conversationId: data["conversationId"] as? String ?? "",
                    messageId: data["messageId"] as? String ?? "",
                    time: data["time"] as? String,
                    location: data["location"] as? String,
                    confidence: data["confidence"] as? Double ?? 0.0
                )
                context.insert(newEvent)
            }
        }
        
        try? context.save()
    }
    
    private func syncDeadlines(_ documents: [QueryDocumentSnapshot], context: ModelContext) {
        for doc in documents {
            let data = doc.data()
            let id = doc.documentID
            
            let descriptor = FetchDescriptor<DigestDeadline>(
                predicate: #Predicate { $0.id == id }
            )
            
            let existing = try? context.fetch(descriptor).first
            
            if let deadline = existing {
                deadline.task = data["task"] as? String ?? deadline.task
                deadline.dueDate = (data["dueDate"] as? Timestamp)?.dateValue() ?? deadline.dueDate
                deadline.priority = data["priority"] as? String ?? deadline.priority
                deadline.status = data["status"] as? String ?? deadline.status
                deadline.completed = data["completed"] as? Bool ?? deadline.completed
            } else {
                let newDeadline = DigestDeadline(
                    id: id,
                    task: data["task"] as? String ?? "",
                    dueDate: (data["dueDate"] as? Timestamp)?.dateValue() ?? Date(),
                    assignedTo: data["assignedTo"] as? String ?? "",
                    conversationId: data["conversationId"] as? String ?? "",
                    messageId: data["messageId"] as? String ?? "",
                    priority: data["priority"] as? String ?? "medium",
                    confidence: data["confidence"] as? Double ?? 0.0
                )
                context.insert(newDeadline)
            }
        }
        
        try? context.save()
    }
    
    private func syncPriorityMessages(_ documents: [QueryDocumentSnapshot], context: ModelContext) {
        for doc in documents {
            let data = doc.data()
            let id = doc.documentID
            
            let descriptor = FetchDescriptor<DigestPriorityMessage>(
                predicate: #Predicate { $0.id == id }
            )
            
            let existing = try? context.fetch(descriptor).first
            
            if let msg = existing {
                msg.status = data["status"] as? String ?? msg.status
            } else {
                let newMsg = DigestPriorityMessage(
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
                context.insert(newMsg)
            }
        }
        
        try? context.save()
    }
    
    private func syncRSVPs(_ documents: [QueryDocumentSnapshot], context: ModelContext) {
        print("🔄 Syncing \(documents.count) RSVPs from Firestore")
        
        for doc in documents {
            let data = doc.data()
            let id = doc.documentID
            
            let descriptor = FetchDescriptor<DigestRSVP>(
                predicate: #Predicate { $0.id == id }
            )
            
            let existing = try? context.fetch(descriptor).first
            
            if let rsvp = existing {
                let oldResponses = rsvp.responsesJSON
                let newResponses = data["responsesJSON"] as? String ?? rsvp.responsesJSON
                
                // ALWAYS update from Firestore (source of truth)
                rsvp.responsesJSON = newResponses
                rsvp.totalInvited = data["totalInvited"] as? Int ?? rsvp.totalInvited
                rsvp.status = data["status"] as? String ?? "pending"
                rsvp.lastUpdated = Date() // ALWAYS touch to force UI refresh
                
                if oldResponses != newResponses {
                    print("  ✏️ Updated RSVP \(id): responses changed")
                    print("     OLD: \(oldResponses)")
                    print("     NEW: \(newResponses)")
                } else {
                    print("  ⏭️ RSVP \(id) refreshed: \(oldResponses)")
                }
            } else {
                let newRSVP = DigestRSVP(
                    id: id,
                    eventId: data["eventId"] as? String ?? "",
                    eventTitle: data["eventTitle"] as? String ?? "",
                    eventDate: (data["eventDate"] as? Timestamp)?.dateValue() ?? Date(),
                    conversationId: data["conversationId"] as? String ?? "",
                    messageId: data["messageId"] as? String ?? "",
                    isHost: data["isHost"] as? Bool ?? false
                )
                newRSVP.status = data["status"] as? String ?? "pending"
                newRSVP.responsesJSON = data["responsesJSON"] as? String ?? "{}"
                newRSVP.totalInvited = data["totalInvited"] as? Int ?? 0
                context.insert(newRSVP)
                print("  ✨ Created new RSVP \(id): \(newRSVP.eventTitle)")
            }
        }
        
        do {
            try context.save()
            print("✅ RSVP sync complete")
        } catch {
            print("❌ Error saving RSVP context: \(error)")
        }
    }
    
    private func syncSuggestions(_ documents: [QueryDocumentSnapshot], context: ModelContext) {
        for doc in documents {
            let data = doc.data()
            let id = doc.documentID
            
            let descriptor = FetchDescriptor<DigestSuggestion>(
                predicate: #Predicate { $0.id == id }
            )
            
            let existing = try? context.fetch(descriptor).first
            
            if let suggestion = existing {
                suggestion.status = data["status"] as? String ?? suggestion.status
            } else {
                let newSuggestion = DigestSuggestion(
                    id: id,
                    type: data["type"] as? String ?? "proactive",
                    priority: data["priority"] as? String ?? "medium",
                    description: data["suggestionDescription"] as? String ?? ""
                )
                newSuggestion.optionsJSON = data["optionsJSON"] as? String ?? "[]"
                context.insert(newSuggestion)
            }
        }
        
        try? context.save()
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

