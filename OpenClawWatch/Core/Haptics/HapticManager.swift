// HapticManager.swift
// MudBug watchOS Client
//
// Premium haptic engine with custom claw-grab pattern.
// Uses async Task.sleep for multi-hit haptic sequences (Swift 6 safe).

import WatchKit

@MainActor
enum HapticManager {

    private static let device = WKInterfaceDevice.current()

    // MARK: - Standard

    static func messageSent()      { device.play(.click) }
    static func responseComplete() { device.play(.success) }
    static func error()            { device.play(.failure) }
    static func connected()        { device.play(.notification) }
    static func scrollSnap()       { device.play(.directionDown) }
    static func voiceStart()       { device.play(.start) }
    static func voiceStop()        { device.play(.stop) }

    // MARK: - Claw Grab 🦞 (double-snap + thump)

    static func clawGrab() {
        Task { @MainActor in
            device.play(.click)
            try? await Task.sleep(for: .milliseconds(60))
            device.play(.click)
            try? await Task.sleep(for: .milliseconds(90))
            device.play(.directionUp)
        }
    }

    // MARK: - Claw Release (thump + click)

    static func clawRelease() {
        Task { @MainActor in
            device.play(.directionDown)
            try? await Task.sleep(for: .milliseconds(100))
            device.play(.click)
        }
    }

    // MARK: - Easter Egg Discovered

    static func easterEggUnlocked() {
        Task { @MainActor in
            device.play(.success)
            try? await Task.sleep(for: .milliseconds(200))
            device.play(.notification)
            try? await Task.sleep(for: .milliseconds(300))
            device.play(.success)
        }
    }
}
