// WatchConnectivityReceiver.swift
// OpenClaw watchOS Client
//
// Receives background push-style notifications from the paired iPhone app
// via WCSession (WatchConnectivity). Ported from the official OpenClaw
// WatchExtension and adapted to feed into mudbug's ChatViewModel.
//
// Supports 3 transport methods:
//   - sendMessage (real-time, requires iPhone app in foreground)
//   - transferUserInfo (queued, guaranteed delivery)
//   - applicationContext (latest-value, overwrites previous)

import Foundation
import WatchConnectivity

/// A message received from the iPhone app via WatchConnectivity.
struct WatchNotifyMessage: Sendable {
    var id: String?
    var title: String
    var body: String
    var sentAtMs: Int?
}

final class WatchConnectivityReceiver: NSObject, @unchecked Sendable {
    private let onMessage: @MainActor (WatchNotifyMessage, String) -> Void
    private let session: WCSession?

    /// - Parameter onMessage: Called on the main actor with the parsed message and transport name.
    init(onMessage: @escaping @MainActor (WatchNotifyMessage, String) -> Void) {
        self.onMessage = onMessage
        if WCSession.isSupported() {
            self.session = WCSession.default
        } else {
            self.session = nil
        }
        super.init()
    }

    func activate() {
        guard let session = self.session else { return }
        session.delegate = self
        session.activate()
    }

    // MARK: - Payload Parsing

    private static func parseNotificationPayload(_ payload: [String: Any]) -> WatchNotifyMessage? {
        guard let type = payload["type"] as? String, type == "watch.notify" else {
            return nil
        }

        let title = (payload["title"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let body = (payload["body"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard title.isEmpty == false || body.isEmpty == false else {
            return nil
        }

        let id = (payload["id"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let sentAtMs = (payload["sentAtMs"] as? Int) ?? (payload["sentAtMs"] as? NSNumber)?.intValue

        return WatchNotifyMessage(
            id: id,
            title: title,
            body: body,
            sentAtMs: sentAtMs
        )
    }

    // MARK: - Delivery

    private func deliver(_ message: WatchNotifyMessage, transport: String) {
        Task { @MainActor in
            self.onMessage(message, transport)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityReceiver: WCSessionDelegate {
    func session(
        _: WCSession,
        activationDidCompleteWith _: WCSessionActivationState,
        error _: (any Error)?
    ) {}

    func session(_: WCSession, didReceiveMessage message: [String: Any]) {
        guard let incoming = Self.parseNotificationPayload(message) else { return }
        deliver(incoming, transport: "sendMessage")
    }

    func session(
        _: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let incoming = Self.parseNotificationPayload(message) else {
            replyHandler(["ok": false])
            return
        }
        replyHandler(["ok": true])
        deliver(incoming, transport: "sendMessage")
    }

    func session(_: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard let incoming = Self.parseNotificationPayload(userInfo) else { return }
        deliver(incoming, transport: "transferUserInfo")
    }

    func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let incoming = Self.parseNotificationPayload(applicationContext) else { return }
        deliver(incoming, transport: "applicationContext")
    }
}
