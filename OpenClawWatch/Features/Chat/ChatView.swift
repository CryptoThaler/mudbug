// ChatView.swift
// MudBug watchOS Client
//
// Premium chat interface with:
// - Mini claw clock in toolbar (taps → Settings)
// - Hidden full-size clock at scroll bottom (scroll to reveal)
// - Quick-action chips + voice dictation button
// - Easter egg for Ultra/Series 11 (Liquid Glass reward)
// - Lobster-esque warm gradient UI
// - Claw-grab haptics on interactions

import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @State private var inputText = ""
    @State private var showClearConfirmation = false
    @State private var showEasterEgg = false
    @State private var clockTaps = 0

    // Lobster palette
    private let lobsterOrange = Color(red: 1.0, green: 0.45, blue: 0.1)
    private let lobsterAmber = Color(red: 0.95, green: 0.55, blue: 0.12)
    private let shellDark = Color(red: 0.08, green: 0.04, blue: 0.02)

    private var isPremium: Bool { DeviceCapability.isPremiumDevice }

    // Quick prompts
    private let chips: [(String, String)] = [
        ("📊", "Status"),
        ("📋", "Summary"),
        ("🔍", "Search"),
        ("⚡", "Run"),
        ("💡", "Ideas"),
        ("📝", "Note"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Warm dark gradient
                LinearGradient(
                    colors: [
                        shellDark,
                        Color(red: 0.06, green: 0.03, blue: 0.01),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    chatList
                    if !viewModel.isGatewayReachable { connectionBanner }
                    inputSection
                }

                // Easter egg overlay
                if showEasterEgg { easterEggOverlay }
            }
            .navigationTitle("MudBug")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        MudBugClockView()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(lobsterOrange.opacity(0.3), lineWidth: 0.5)
                            )
                            .onTapGesture {
                                clockTaps += 1
                                if clockTaps >= 5 && isPremium {
                                    triggerEasterEgg()
                                }
                            }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                        HapticManager.clawRelease()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red.opacity(0.7))
                    }
                }
            }
            .confirmationDialog("Clear?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Clear All", role: .destructive) { viewModel.clearConversation() }
                Button("Cancel", role: .cancel) {}
            }
            .task { await viewModel.checkGatewayConnection() }
        }
    }

    // MARK: - Chat List + Hidden Clock at Bottom

    private var chatList: some View {
        ScrollViewReader { proxy in
            List {
                if viewModel.messages.isEmpty {
                    // Full clock as idle state
                    clockFace
                } else {
                    // Messages
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }

                    // Hidden clock at bottom — scroll to reveal
                    hiddenClockReveal
                        .id("bottom-clock")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: viewModel.messages.count) {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Full Clock Face (Empty State)

    private var clockFace: some View {
        VStack(spacing: 2) {
            MudBugClockView()
                .frame(height: 110)
            Text("Tap a chip or dictate")
                .font(.system(size: 8, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
        .listRowBackground(Color.clear)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }

    // MARK: - Hidden Clock (Bottom of Scroll)

    private var hiddenClockReveal: some View {
        VStack(spacing: 4) {
            Divider()
                .overlay(lobsterOrange.opacity(0.2))
            MudBugClockView()
                .frame(height: 100)
            Text("🦞 MudBug Time")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(lobsterOrange.opacity(0.5))
        }
        .listRowBackground(Color.clear)
        .padding(.top, 8)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 3) {
            if !viewModel.isThinking {
                chipBar
            }
            compactInput
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.4))
                .overlay(
                    Rectangle().fill(
                        LinearGradient(
                            colors: [lobsterOrange.opacity(0.03), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                )
        }
    }

    private var chipBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Voice dictation button
                Button {
                    HapticManager.clawGrab()
                    // Trigger system dictation by focusing TextField
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(lobsterOrange)
                        .padding(5)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle().strokeBorder(lobsterOrange.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                }
                .buttonStyle(.plain)

                // Quick prompts
                ForEach(chips, id: \.1) { emoji, label in
                    Button {
                        Task { await viewModel.sendMessage(label) }
                        HapticManager.clawGrab()
                    } label: {
                        HStack(spacing: 1) {
                            Text(emoji).font(.system(size: 8))
                            Text(label).font(.system(size: 8, weight: .medium, design: .rounded))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule().strokeBorder(
                                        lobsterOrange.opacity(0.15), lineWidth: 0.4
                                    )
                                )
                        )
                        .foregroundStyle(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 3)
        }
    }

    private var compactInput: some View {
        HStack(spacing: 3) {
            TextField("Ask MudBug…", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    lobsterOrange.opacity(0.12), lineWidth: 0.4
                                )
                        )
                )
                .disabled(viewModel.isThinking)
                .onSubmit { submitMessage() }

            if viewModel.isThinking {
                ProgressView().tint(lobsterOrange).scaleEffect(0.6)
            } else {
                Button { submitMessage() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.gray.opacity(0.3) : lobsterOrange
                        )
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 3)
    }

    // MARK: - Connection Banner

    private var connectionBanner: some View {
        HStack(spacing: 3) {
            Image(systemName: "wifi.slash").font(.system(size: 8))
            Text("Gateway Unreachable")
                .font(.system(size: 8, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.5))
    }

    // MARK: - Easter Egg (Premium Devices Only)

    private var easterEggOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 8) {
                Text("🦞✨")
                    .font(.system(size: 36))
                Text("LIQUID GLASS")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [lobsterOrange, lobsterAmber, .white, lobsterAmber, lobsterOrange],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                Text("Premium MudBug Mode")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [lobsterOrange, .white.opacity(0.5), lobsterAmber],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .frame(height: 30)
                    .overlay(
                        Text("Exclusive to your Watch")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    )
                    .padding(.horizontal, 20)
            }
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.3)) { showEasterEgg = false }
        }
        .transition(.opacity)
    }

    // MARK: - Actions

    private func submitMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        HapticManager.messageSent()
        Task { await viewModel.sendMessage(text) }
    }

    private func triggerEasterEgg() {
        clockTaps = 0
        HapticManager.easterEggUnlocked()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showEasterEgg = true
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView(viewModel: ChatViewModel())
}
