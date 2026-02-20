// MessageBubble.swift
// MudBug watchOS Client
//
// Lobster-esque chat bubbles: warm orange glow with black illuminated text.
// Premium devices get enhanced Liquid Glass depth effects.
// Tap any assistant bubble to hear it read aloud.

import SwiftUI

struct MessageBubble: View {
    let message: OpenClawMessage

    // Lobster palette 🦞
    private let lobsterOrange = Color(red: 1.0, green: 0.45, blue: 0.1)
    private let lobsterAmber = Color(red: 0.95, green: 0.55, blue: 0.12)
    private let lobsterDeep = Color(red: 0.6, green: 0.2, blue: 0.05)
    private let shellHighlight = Color(red: 1.0, green: 0.7, blue: 0.3)

    private var isPremium: Bool { DeviceCapability.isPremiumDevice }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            if message.role == .user { Spacer(minLength: 12) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 2) {
                // Role label
                if message.role != .user {
                    HStack(spacing: 3) {
                        Text("🦞").font(.system(size: 9))
                        Text("MudBug")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(lobsterOrange.opacity(0.7))
                    }
                }

                // Content
                if message.isThinking {
                    thinkingDots
                } else if message.content.hasPrefix("⚠️") {
                    errorBubble
                } else {
                    contentBubble
                }

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }

            if message.role != .user { Spacer(minLength: 12) }
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Lobster Content Bubble

    private var contentBubble: some View {
        Text(message.content)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(message.role == .user ? .white : .black)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                if message.role == .user {
                    // User: deep shell with glass overlay
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [lobsterDeep, lobsterDeep.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial.opacity(isPremium ? 0.4 : 0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            lobsterOrange.opacity(0.6),
                                            shellHighlight.opacity(0.2),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.6
                                )
                        )
                } else {
                    // MudBug: warm orange glow with black text
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    lobsterAmber.opacity(0.85),
                                    lobsterOrange.opacity(0.7),
                                    lobsterDeep.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial.opacity(isPremium ? 0.35 : 0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            shellHighlight.opacity(0.5),
                                            lobsterOrange.opacity(0.3),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isPremium ? 0.8 : 0.4
                                )
                        )
                }
            }
            .shadow(
                color: message.role == .user
                    ? lobsterDeep.opacity(0.3)
                    : lobsterOrange.opacity(isPremium ? 0.25 : 0.1),
                radius: isPremium ? 6 : 3, x: 0, y: 2
            )
            .onTapGesture {
                if message.role == .assistant {
                    VoiceEngine.shared.toggle(message.content)
                    HapticManager.clawGrab()
                }
            }
    }

    // MARK: - Error Bubble

    private var errorBubble: some View {
        Text(message.content)
            .font(.system(size: 12, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.red.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.red.opacity(0.4), lineWidth: 0.5)
                    )
            )
    }

    // MARK: - Thinking Dots

    private var thinkingDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(lobsterOrange)
                    .frame(width: 5, height: 5)
                    .scaleEffect(1.0)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                        value: true
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(lobsterAmber.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.2))
                )
        )
    }
}
