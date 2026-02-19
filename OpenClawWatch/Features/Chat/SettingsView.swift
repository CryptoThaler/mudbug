// SettingsView.swift
// MudBug watchOS Client
//
// Minimal settings screen for Gateway configuration and diagnostics.

import SwiftUI

struct SettingsView: View {
    @State private var isCheckingConnection = false
    @State private var connectionStatus: ConnectionStatus = .unknown

    private let clawOrange = Color(red: 1.0, green: 0.45, blue: 0.1)

    enum ConnectionStatus {
        case unknown, checking, connected, failed
    }

    var body: some View {
        List {
            // MARK: - Gateway Info
            Section("Gateway") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Endpoint")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(APIConstants.baseUrl)
                        .font(.system(size: 11, design: .monospaced))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                .listRowBackground(Color.gray.opacity(0.1))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Model")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(APIConstants.model)
                        .font(.system(size: 12, design: .monospaced))
                }
                .listRowBackground(Color.gray.opacity(0.1))
            }

            // MARK: - Connection Test
            Section("Diagnostics") {
                Button {
                    testConnection()
                } label: {
                    HStack {
                        Image(systemName: statusIcon)
                            .foregroundStyle(statusColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Test Connection")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                            Text(statusText)
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if connectionStatus == .checking {
                            ProgressView()
                                .tint(clawOrange)
                                .scaleEffect(0.6)
                        }
                    }
                }
                .disabled(connectionStatus == .checking)
                .listRowBackground(Color.gray.opacity(0.1))
            }

            // MARK: - About
            Section("About") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("🦞 MudBug Watch")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Spacer()
                        Text("v1.0.0")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Text("A thin Gateway client for watchOS 12")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.gray.opacity(0.1))
            }
        }
        .navigationTitle("Settings")
    }

    // MARK: - Connection Test

    private func testConnection() {
        connectionStatus = .checking
        Task {
            let reachable = await OpenClawAPI.shared.pingGateway()
            connectionStatus = reachable ? .connected : .failed
            if reachable {
                HapticManager.connected()
            } else {
                HapticManager.error()
            }
        }
    }

    // MARK: - Status Helpers

    private var statusIcon: String {
        switch connectionStatus {
        case .unknown: return "questionmark.circle"
        case .checking: return "antenna.radiowaves.left.and.right"
        case .connected: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch connectionStatus {
        case .unknown: return .gray
        case .checking: return clawOrange
        case .connected: return .green
        case .failed: return .red
        }
    }

    private var statusText: String {
        switch connectionStatus {
        case .unknown: return "Tap to verify Gateway connectivity"
        case .checking: return "Connecting…"
        case .connected: return "Gateway is reachable ✓"
        case .failed: return "Cannot reach Gateway"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
}
