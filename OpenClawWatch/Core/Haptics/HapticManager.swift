// HapticManager.swift
// OpenClaw watchOS Client
//
// Centralized haptic feedback for the Watch.
// Uses WatchKit's WKInterfaceDevice for hardware-level haptics.

import WatchKit

enum HapticManager {

    /// Played when the assistant finishes streaming a response.
    /// Gives the user a physical cue to look at their wrist.
    static func responseComplete() {
        WKInterfaceDevice.current().play(.success)
    }

    /// Played when the user sends a message.
    static func messageSent() {
        WKInterfaceDevice.current().play(.click)
    }

    /// Played on network errors or auth failures.
    static func error() {
        WKInterfaceDevice.current().play(.failure)
    }

    /// Played when the Gateway connection is established.
    static func connected() {
        WKInterfaceDevice.current().play(.notification)
    }

    /// Subtle directional haptic — used for scroll-to-bottom.
    static func scrollSnap() {
        WKInterfaceDevice.current().play(.directionDown)
    }
}
