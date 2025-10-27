//
//  DigestSuggestion.swift
//  weftly
//
//  Created for unified agent architecture (PR #28)
//  Proactive suggestions from AI

import Foundation
import SwiftData

@Model
final class DigestSuggestion {
    @Attribute(.unique) var id: String
    var type: String // "conflict_resolution" | "reminder" | "proactive"
    var priority: String // "high" | "medium" | "low"
    var suggestionDescription: String
    var optionsJSON: String // JSON string of options array
    var status: String // "pending" | "accepted" | "dismissed"
    var createdAt: Date
    
    init(
        id: String,
        type: String,
        priority: String,
        description: String
    ) {
        self.id = id
        self.type = type
        self.priority = priority
        self.suggestionDescription = description
        self.optionsJSON = "[]"
        self.status = "pending"
        self.createdAt = Date()
    }
    
    // Computed property to access options
    var options: [String] {
        get {
            guard let data = optionsJSON.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                optionsJSON = json
            }
        }
    }
}

