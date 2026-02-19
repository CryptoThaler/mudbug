// ChatView.swift
// MudBug watchOS Client
//
// The primary chat interface for watchOS 12 with Liquid Glass design.
// Features a mini Claw Clock in the toolbar, compact input bar,
// and quick-action prompt chips for maximum input options.

import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @State private var inputText = ""
    @State private var showClearConfirmation = false

    // MudBug brand
    private let clawOrange = Color(red: 1.0, green: 0.45, blue: 0.1)

    // Quick-action prompts
    private let quickPrompts = [
        ("📊", "Status"),
        ("📋", "Summary"),
        ("🔍", "Search"),
        ("⚡", "Quick task"),
        ("💡", "Ideas"),
        ("📝", "Notes"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.03, blue: 0.08),
                        Color(red: 0.03, green: 0.02, blue: 0.06)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    chatList
                    if !viewModel.isGatewayReachable {
                        connectionBanner
                    }
                    inputSection
                }
            }
            .navigationTitle("MudBug")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        MudBugClockView()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                }
            }
            .confirmationDialog(
                "Clear?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) {
                    viewModel.clearConversation()
                }
                Button("Cancel", role: .cancel) {}
            }
            .task {
                await viewModel.checkGatewayConnection()
            }
        }
    }

    // MARK: - Chat List

    private var chatList: some View {
        ScrollViewReader { proxy in
            List {
                if viewModel.messages.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                            .transition(.push(from: .bottom))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: viewModel.messages.count) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                }
                HapticManager.scrollSnap()
            }
        }
    }

    // MARK: - Input Section (Compact + Quick Actions)

    private var inputSection: some View {
        VStack(spacing: 4) {
            // Quick action chips
            if viewModel.messages.isEmpty || !viewModel.isThinking {
                quickActionBar
            }
            // Compact input bar
            compactInputBar
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.04), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        }
    }

    private var quickActionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(quickPrompts, id: \.1) { emoji, label in
                    Button {
                        sendQuickPrompt(label)
                    } label: {
                        HStack(spacing: 2) {
                            Text(emoji)
                                .font(.system(size: 9))
                            Text(label)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            clawOrange.opacity(0.2),
                                            lineWidth: 0.5
                                        )
                                )
                        )
                        .foregroundStyle(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
        }
    }

    private var compactInputBar: some View {
        HStack(spacing: 4) {
            TextField("Ask MudBug…", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.2),
                                            .white.opacity(0.06),
                                            clawOrange.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                }
                .disabled(viewModel.isThinking)
                .onSubmit { submitMessage() }

            if viewModel.isThinking {
                ProgressView()
                    .tint(clawOrange)
                    .scaleEffect(0.7)
            } else {
                Button { submitMessage() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.gray.opacity(0.4)
                                : clawOrange
                        )
                        .shadow(
                            color: inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? .clear
                                : clawOrange.opacity(0.4),
                            radius: 4, x: 0, y: 0
                        )
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    // MARK: - Empty State (Full Clock)

    private var emptyState: some View {
        VStack(spacing: 4) {
            MudBugClockView()
                .frame(height: 120)
                .padding(.horizontal, 4)
            Text("Tap a chip or type to start")
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .listRowBackground(Color.clear)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Connection Banner

    private var connectionBanner: some View {
        HStack(spacing: 3) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 8))
            Text("Gateway Unreachable")
                .font(.system(size: 9, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Rectangle().fill(Color.red.opacity(0.6)))
        }
    }

    // MARK: - Actions

    private func submitMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        Task { await viewModel.sendMessage(text) }
    }

    private func sendQuickPrompt(_ label: String) {
        Task { await viewModel.sendMessage(label) }
        HapticManager.messageSent()
    }
}

// MARK: - Preview

#Preview {
    ChatView(viewModel: ChatViewModel())
}
