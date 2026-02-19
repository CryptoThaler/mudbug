// ConversationStore.swift
// OpenClaw watchOS Client
//
// Lightweight persistence layer using UserDefaults.
// Stores conversation history so the user sees their last chat
// when reopening the app from the Watch Dock.
//
// For a v2, consider migrating to SwiftData for richer queries.

import Foundation

final class ConversationStore: @unchecked Sendable {
    static let shared = ConversationStore()

    private let defaults = UserDefaults.standard
    private let messagesKey = "openclaw_messages"
    private let maxStoredMessages = 50

    private init() {}

    // MARK: - Codable Wrapper

    private struct StoredMessage: Codable {
        let id: String
        let role: String
        let content: String
        let timestamp: Date
    }

    // MARK: - Save

    func save(messages: [OpenClawMessage]) {
        let stored = messages.suffix(maxStoredMessages).map { msg in
            StoredMessage(
                id: msg.id.uuidString,
                role: msg.role.rawValue,
                content: msg.content,
                timestamp: msg.timestamp
            )
        }

        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: messagesKey)
        }
    }

    // MARK: - Load

    func load() -> [OpenClawMessage] {
        guard let data = defaults.data(forKey: messagesKey),
              let stored = try? JSONDecoder().decode([StoredMessage].self, from: data) else {
            return []
        }

        return stored.compactMap { s in
            guard let role = OpenClawRole(rawValue: s.role),
                  let uuid = UUID(uuidString: s.id) else { return nil }
            return OpenClawMessage(
                id: uuid,
                role: role,
                content: s.content,
                timestamp: s.timestamp
            )
        }
    }

    // MARK: - Clear

    func clear() {
        defaults.removeObject(forKey: messagesKey)
    }
}
