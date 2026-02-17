// OpenClawApp.swift
// OpenClaw watchOS Client
//
// Entry point for the OpenClaw Watch app.
// Targets watchOS 12+ and Apple Watch Series 11.

import SwiftUI

@main
struct OpenClawApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
        }
    }
}
