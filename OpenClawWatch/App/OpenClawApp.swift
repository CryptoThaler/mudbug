// OpenClawApp.swift
// OpenClaw watchOS Client
//
// Entry point for the OpenClaw Watch app.
// Targets watchOS 12+ and Apple Watch Series 11.
// Activates WatchConnectivity to receive push notifications from the paired iPhone.

import SwiftUI

@main
struct OpenClawApp: App {
    @State private var viewModel = ChatViewModel()
    @State private var receiver: WatchConnectivityReceiver?

    var body: some Scene {
        WindowGroup {
            ChatView(viewModel: viewModel)
                .task {
                    if receiver == nil {
                        let r = WatchConnectivityReceiver { [viewModel] message, transport in
                            viewModel.consumeNotification(message, transport: transport)
                        }
                        r.activate()
                        receiver = r
                    }
                }
        }
    }
}
