// MessageBubble.swift
// OpenClaw watchOS Client
//
// Liquid Glass chat bubble component for watchOS 12.
// Uses .glassBackgroundEffect() for translucent, depth-aware bubble surfaces
// with OpenClaw's signature orange accent. Falls back to .ultraThinMaterial
// where Liquid Glass is unavailable.

import SwiftUI

struct MessageBubble: View {
    let message: OpenClawMessage

    // OpenClaw brand colors
    private let clawOrange = Color(red: 1.0, green: 0.45, blue: 0.1)
    private let userBlue = Color(red: 0.25, green: 0.55, blue: 1.0)

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if message.role == .user {
                Spacer(minLength: 16)
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

            if message.role == .assistant || message.role == .system || message.role == .tool {
                Spacer(minLength: 16)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
    }

    // MARK: - Content Bubble (Liquid Glass)

    private var contentBubble: some View {
        Text(message.content)
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .foregroundStyle(message.role == .user ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                if message.role == .user {
                    // User bubble: vibrant blue gradient with glass overlay
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    userBlue,
                                    userBlue.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial.opacity(0.3))
                        )
                        .overlay(
                            // Subtle inner border for glass edge effect
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.5),
                                            .white.opacity(0.1),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.75
                                )
                        )
                } else {
                    // Assistant bubble: translucent glass panel
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.08),
                                            .clear,
                                            clawOrange.opacity(0.04)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.3),
                                            .white.opacity(0.08),
                                            clawOrange.opacity(0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                }
            }
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    // MARK: - Thinking Indicator (Glass)

    private var thinkingIndicator: some View {
        HStack(spacing: 6) {
            // Animated dots instead of ProgressView for a more refined look
            ThinkingDots(color: clawOrange)
                .frame(width: 32, height: 12)
            Text("Thinking…")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(clawOrange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(clawOrange.opacity(0.2), lineWidth: 0.5)
                )
        }
        .shadow(color: clawOrange.opacity(0.1), radius: 6, x: 0, y: 2)
    }

    // MARK: - Error Bubble (Glass + Red Tint)

    private var errorBubble: some View {
        Text(message.content)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.red)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.red.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.red.opacity(0.25), lineWidth: 0.5)
                    )
            }
    }

    // MARK: - Helpers

    private var roleName: String {
        switch message.role {
        case .assistant: return "OpenClaw"
        case .system: return "System"
        case .tool: return "Tool"
        case .user: return "You"
        }
    }
}

// MARK: - Thinking Dots Animation

struct ThinkingDots: View {
    let color: Color
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .scaleEffect(phase == index ? 1.3 : 0.7)
                    .opacity(phase == index ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.15),
                        value: phase
                    )
            }
        }
        .onAppear {
            // Cycle through dots
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
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
