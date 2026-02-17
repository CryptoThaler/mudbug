// ChatView.swift
// OpenClaw watchOS Client
//
// The primary chat interface for watchOS 12.
// Uses NavigationStack + ScrollViewReader for auto-scrolling.
// Supports Digital Crown scrolling, Smart Input, and context menus.

import SwiftUI

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @State private var inputText = ""
    @State private var showSettings = false
    @State private var showClearConfirmation = false

    // OpenClaw brand
    private let clawOrange = Color(red: 1.0, green: 0.45, blue: 0.1)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat messages
                chatList

                // Connection status bar
                if !viewModel.isGatewayReachable {
                    connectionBanner
                }

                // Input field
                inputBar
            }
            .navigationTitle("OpenClaw 🦞")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Label("Clear Chat", systemImage: "trash")
                        }

                        Button {
                            Task { await viewModel.checkGatewayConnection() }
                        } label: {
                            Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
                        }

                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(clawOrange)
                    }
                }
            }
            .confirmationDialog(
                "Clear Conversation?",
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
            .onChange(of: viewModel.messages.count) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                }
                HapticManager.scrollSnap()
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 6) {
            TextField("Ask OpenClaw…", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .disabled(viewModel.isThinking)
                .onSubmit {
                    submitMessage()
                }

            if viewModel.isThinking {
                ProgressView()
                    .tint(clawOrange)
                    .scaleEffect(0.8)
            } else {
                Button {
                    submitMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.gray.opacity(0.4)
                                : clawOrange
                        )
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🦞")
                .font(.system(size: 40))
            Text("OpenClaw")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(clawOrange)
            Text("Your AI agent on your wrist.\nType or dictate to get started.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .listRowBackground(Color.clear)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Connection Banner

    private var connectionBanner: some View {
        HStack(spacing: 4) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 10))
            Text("Gateway Unreachable")
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.85))
    }

    // MARK: - Actions

    private func submitMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        Task {
            await viewModel.sendMessage(text)
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView()
}
