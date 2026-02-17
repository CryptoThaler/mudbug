// MessageBubble.swift
// OpenClaw watchOS Client
//
// A polished chat bubble component optimized for the Apple Watch display.
// Uses OpenClaw's signature orange for branding and adaptive sizing for Series 11.

import SwiftUI

struct MessageBubble: View {
    let message: OpenClawMessage

    // OpenClaw brand colors
    private let clawOrange = Color(red: 1.0, green: 0.45, blue: 0.1)
    private let userBlue = Color(red: 0.2, green: 0.5, blue: 1.0)

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if message.role == .user {
                Spacer(minLength: 20)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {

                // Role label (only for non-user messages)
                if message.role != .user {
                    HStack(spacing: 4) {
                        if message.role == .assistant {
                            Text("🦞")
                                .font(.system(size: 10))
                        }
                        Text(roleName)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                // Message content
                if message.isThinking {
                    thinkingIndicator
                } else if message.content.hasPrefix("⚠️") {
                    errorBubble
                } else {
                    contentBubble
                }

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            if message.role == .assistant || message.role == .system {
                Spacer(minLength: 20)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
    }

    // MARK: - Subviews

    private var contentBubble: some View {
        Text(message.content)
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .foregroundStyle(message.role == .user ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(bubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var thinkingIndicator: some View {
        HStack(spacing: 6) {
            ProgressView()
                .tint(clawOrange)
                .scaleEffect(0.7)
            Text("Thinking…")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(clawOrange)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var errorBubble: some View {
        Text(message.content)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.red)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Helpers

    private var bubbleBackground: some ShapeStyle {
        if message.role == .user {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [userBlue, userBlue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(Color.gray.opacity(0.2))
        }
    }

    private var roleName: String {
        switch message.role {
        case .assistant: return "OpenClaw"
        case .system: return "System"
        case .tool: return "Tool"
        case .user: return "You"
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        MessageBubble(message: OpenClawMessage(
            role: .user,
            content: "What's the weather in Bozeman?"
        ))

        MessageBubble(message: OpenClawMessage(
            role: .assistant,
            content: "Currently 28°F in Bozeman, MT. Clear skies with a high of 35°F expected today. 🏔️"
        ))

        MessageBubble(message: OpenClawMessage(
            role: .assistant,
            content: "",
            isThinking: true
        ))

        MessageBubble(message: OpenClawMessage(
            role: .assistant,
            content: "⚠️ Cannot reach OpenClaw Gateway."
        ))
    }
}
