// ChatView.swift
// OpenClaw watchOS Client
//
// The primary chat interface for watchOS 12 with Liquid Glass design.
// Uses NavigationStack + ScrollViewReader for auto-scrolling.
// Supports Digital Crown scrolling, Smart Input, and context menus.
// Accepts viewModel from the app entry point (injected with WatchConnectivity).

import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @State private var inputText = ""
    @State private var showSettings = false
    @State private var showClearConfirmation = false

    // OpenClaw brand
    private let clawOrange = Color(red: 1.0, green: 0.45, blue: 0.1)

    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient background
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
                    // Chat messages
                    chatList

                    // Connection status bar
                    if !viewModel.isGatewayReachable {
                        connectionBanner
                    }

                    // Liquid Glass input bar
                    inputBar
                }
            }
            .navigationTitle("OpenClaw 🦞")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .foregroundStyle(clawOrange)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red.opacity(0.8))
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
            .scrollContentBackground(.hidden)
            .onChange(of: viewModel.messages.count) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                }
                HapticManager.scrollSnap()
            }
        }
    }

    // MARK: - Liquid Glass Input Bar

    private var inputBar: some View {
        HStack(spacing: 6) {
            TextField("Ask OpenClaw…", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.25),
                                            .white.opacity(0.08),
                                            clawOrange.opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.6
                                )
                        )
                }
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
                        .font(.system(size: 28))
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
                            radius: 6, x: 0, y: 0
                        )
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            // Glass backdrop for the entire input area
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.05), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("🦞")
                .font(.system(size: 44))
                .shadow(color: clawOrange.opacity(0.4), radius: 12, x: 0, y: 0)
            Text("OpenClaw")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [clawOrange, clawOrange.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text("Your AI agent on your wrist.\nType or dictate to get started.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .listRowBackground(Color.clear)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Connection Banner (Glass)

    private var connectionBanner: some View {
        HStack(spacing: 4) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 10))
            Text("Gateway Unreachable")
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.red.opacity(0.6))
                )
        }
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
    ChatView(viewModel: ChatViewModel())
}
