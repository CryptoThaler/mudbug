// ChatViewModel.swift
// OpenClaw watchOS Client
//
// The primary business logic & state manager for the chat interface.
// Handles message lifecycle, streaming, persistence, and error states.

import SwiftUI
import Observation

@Observable
final class ChatViewModel {

    // MARK: - Published State

    var messages: [OpenClawMessage] = []
    var isThinking: Bool = false
    var errorMessage: String?
    var isGatewayReachable: Bool = true

    // MARK: - Private State

    private let api = OpenClawAPI.shared
    private let store = ConversationStore.shared
    private var deliveredKeys: Set<String> = []

    // MARK: - Initialization

    init() {
        messages = store.load()
    }

    // MARK: - WatchConnectivity Incoming Notifications

    /// Consumes a notification pushed from the paired iPhone via WCSession.
    /// Displays it as an assistant message in the chat and triggers haptics.
    @MainActor
    func consumeNotification(_ message: WatchNotifyMessage, transport: String) {
        let deliveryKey = makeDeliveryKey(message)
        guard !deliveredKeys.contains(deliveryKey) else { return }
        deliveredKeys.insert(deliveryKey)

        let title = message.title.isEmpty ? "OpenClaw" : message.title
        let content = message.body.isEmpty
            ? title
            : (title == "OpenClaw" ? message.body : "**\(title)**\n\(message.body)")

        let msg = OpenClawMessage(role: .assistant, content: content)
        messages.append(msg)
        store.save(messages: messages)
        HapticManager.responseComplete()
    }

    private func makeDeliveryKey(_ message: WatchNotifyMessage) -> String {
        if let id = message.id, !id.isEmpty {
            return "id:\(id)"
        }
        return "content:\(message.title)|\(message.body)|\(message.sentAtMs ?? 0)"
    }

    // MARK: - Send Message (Streaming)

    func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        errorMessage = nil

        // 1. Append user message
        let userMsg = OpenClawMessage(role: .user, content: trimmed)
        messages.append(userMsg)
        HapticManager.messageSent()

        // 2. Add empty assistant bubble + thinking state
        isThinking = true
        let aiMsg = OpenClawMessage(role: .assistant, content: "", isThinking: true)
        messages.append(aiMsg)
        let aiIndex = messages.count - 1

        // 3. Build conversation history for context
        let history = buildConversationHistory()

        // 4. Stream the response
        do {
            let stream = try await api.streamChat(messages: history)

            // Mark as no longer "thinking" once first chunk arrives
            var receivedFirstChunk = false

            for try await chunk in stream {
                if !receivedFirstChunk {
                    receivedFirstChunk = true
                    messages[aiIndex].isThinking = false
                    isThinking = false
                }
                messages[aiIndex].content += chunk
            }

            // Ensure thinking state is cleared even if stream was empty
            messages[aiIndex].isThinking = false
            isThinking = false

            // 5. Haptic on completion
            HapticManager.responseComplete()

        } catch let error as OpenClawError {
            handleError(error, at: aiIndex)
        } catch {
            handleError(.networkError(error), at: aiIndex)
        }

        // 6. Persist conversation
        store.save(messages: messages)
    }

    // MARK: - Quick Send (Non-Streaming, for Complications)

    func quickSend(_ text: String) async -> String? {
        let history: [ChatCompletionRequest.ChatRequestMessage] = [
            .init(role: "user", content: text)
        ]

        do {
            return try await api.sendChat(messages: history)
        } catch {
            return nil
        }
    }

    // MARK: - Gateway Connectivity

    func checkGatewayConnection() async {
        isGatewayReachable = await api.pingGateway()
        if isGatewayReachable {
            HapticManager.connected()
        }
    }

    // MARK: - Clear Conversation

    func clearConversation() {
        messages.removeAll()
        store.clear()
        errorMessage = nil
    }

    // MARK: - Retry Last Message

    func retryLastMessage() async {
        // Find the last user message and re-send it
        guard let lastUserMsg = messages.last(where: { $0.role == .user }) else { return }

        // Remove the failed assistant response
        if let lastMsg = messages.last, lastMsg.role == .assistant {
            messages.removeLast()
        }
        // Remove the user message (sendMessage will re-add it)
        if let lastMsg = messages.last, lastMsg.role == .user {
            messages.removeLast()
        }

        await sendMessage(lastUserMsg.content)
    }

    // MARK: - Private Helpers

    private func buildConversationHistory() -> [ChatCompletionRequest.ChatRequestMessage] {
        // Send the last 20 messages for context (to stay within token limits)
        let recentMessages = messages.suffix(20)
        return recentMessages.compactMap { msg in
            guard !msg.content.isEmpty else { return nil }
            return ChatCompletionRequest.ChatRequestMessage(
                role: msg.role.rawValue,
                content: msg.content
            )
        }
    }

    private func handleError(_ error: OpenClawError, at index: Int) {
        isThinking = false
        messages[index].isThinking = false
        messages[index].content = "⚠️ \(error.localizedDescription)"
        errorMessage = error.localizedDescription
        HapticManager.error()

        if case .gatewayUnreachable = error {
            isGatewayReachable = false
        }
    }
}
