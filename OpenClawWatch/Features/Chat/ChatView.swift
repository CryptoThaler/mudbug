// ChatView.swift
// MudBug watchOS Client
//
// Single-layer chat: maximum screen for I/O.
// Terminal-style input with mic/keyboard toggle.
// Mini claw clock stays in the top-right toolbar only.

import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @State private var inputText = ""
    @State private var showClearConfirmation = false
    @State private var showEasterEgg = false
    @State private var clockTaps = 0
    @State private var useMic = false

    private let lobsterOrange = Color(red: 1.0, green: 0.45, blue: 0.1)
    private let shellDark = Color(red: 0.08, green: 0.04, blue: 0.02)
    private var isPremium: Bool { DeviceCapability.isPremiumDevice }

    var body: some View {
        NavigationStack {
            ZStack {
                shellDark.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Full-height chat area
                    chatList

                    // Connection status
                    if !viewModel.isGatewayReachable {
                        connectionBanner
                    }

                    // Terminal input
                    terminalInput
                }

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
                                Circle().strokeBorder(lobsterOrange.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.3).onEnded { _ in
                            clockTaps += 1
                            if clockTaps >= 5 && isPremium { triggerEasterEgg() }
                        }
                    )
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

    // MARK: - Chat List (Maximum Height)

    private var chatList: some View {
        ScrollViewReader { proxy in
            List {
                if viewModel.messages.isEmpty {
                    // Minimal prompt — no clock, just text
                    Text("🦞 Ready.")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(lobsterOrange.opacity(0.6))
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                } else {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: viewModel.messages.count) {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Terminal-Style Input

    private var terminalInput: some View {
        HStack(spacing: 4) {
            // Prompt character
            Text("›")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(lobsterOrange)

            // Text field
            TextField("_", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .disabled(viewModel.isThinking)
                .onSubmit { submitMessage() }

            // Mic / Keyboard toggle
            Button {
                useMic.toggle()
                HapticManager.clawGrab()
            } label: {
                Image(systemName: useMic ? "keyboard" : "mic.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(lobsterOrange.opacity(0.8))
            }
            .buttonStyle(.plain)

            // Send / Loading
            if viewModel.isThinking {
                ProgressView().tint(lobsterOrange).scaleEffect(0.6)
            } else {
                Button { submitMessage() } label: {
                    Image(systemName: "return")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? .gray.opacity(0.3) : lobsterOrange
                        )
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Rectangle()
                .fill(Color(red: 0.05, green: 0.03, blue: 0.01))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(lobsterOrange.opacity(0.15)),
                    alignment: .top
                )
        )
    }

    // MARK: - Connection Banner

    private var connectionBanner: some View {
        HStack(spacing: 3) {
            Image(systemName: "wifi.slash").font(.system(size: 8))
            Text("Gateway Unreachable")
                .font(.system(size: 8, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.5))
    }

    // MARK: - Easter Egg

    private var easterEggOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 8) {
                Text("🦞✨").font(.system(size: 36))
                Text("LIQUID GLASS")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [lobsterOrange, .white, lobsterOrange],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                Text("Premium MudBug Mode")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.3)) { showEasterEgg = false }
        }
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
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showEasterEgg = true }
    }
}

#Preview {
    ChatView(viewModel: ChatViewModel())
}
