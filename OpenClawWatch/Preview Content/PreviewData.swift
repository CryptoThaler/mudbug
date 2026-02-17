// PreviewData.swift
// OpenClaw watchOS Client
//
// Mock data for SwiftUI Previews and development.
// These messages simulate a realistic conversation with OpenClaw.

import Foundation

enum PreviewData {

    static let sampleConversation: [OpenClawMessage] = [
        OpenClawMessage(
            role: .user,
            content: "What's the weather like in Bozeman today?",
            timestamp: Date().addingTimeInterval(-300)
        ),
        OpenClawMessage(
            role: .assistant,
            content: "Currently 28°F (-2°C) in Bozeman, MT with clear skies. Expected high of 35°F (2°C). Wind from the NW at 8 mph. Great day for a hike in the Bridgers! 🏔️",
            timestamp: Date().addingTimeInterval(-290)
        ),
        OpenClawMessage(
            role: .user,
            content: "Summarize my last 5 Telegram messages",
            timestamp: Date().addingTimeInterval(-120)
        ),
        OpenClawMessage(
            role: .assistant,
            content: "Here's your Telegram summary:\n\n1. **Alice**: Confirmed dinner at 7pm tonight\n2. **Bob**: Shared a link to the Montana gem show\n3. **Dev Group**: CI pipeline passed ✅\n4. **Mom**: Asked about weekend plans\n5. **CryptoThaler**: New sapphire NFT drop tomorrow",
            timestamp: Date().addingTimeInterval(-110)
        ),
        OpenClawMessage(
            role: .user,
            content: "Reply to Mom: I'll be in Helena Saturday, let's grab lunch",
            timestamp: Date().addingTimeInterval(-60)
        ),
        OpenClawMessage(
            role: .assistant,
            content: "✅ Message sent to Mom via Telegram:\n\"I'll be in Helena Saturday, let's grab lunch\"",
            timestamp: Date().addingTimeInterval(-55)
        ),
    ]

    static let thinkingMessage = OpenClawMessage(
        role: .assistant,
        content: "",
        isThinking: true,
        timestamp: Date()
    )

    static let errorMessage = OpenClawMessage(
        role: .assistant,
        content: "⚠️ Cannot reach OpenClaw Gateway. Verify the URL and ensure the server is running.",
        timestamp: Date()
    )

    static let singleUserMessage = OpenClawMessage(
        role: .user,
        content: "What sapphire claims are active in Philipsburg?",
        timestamp: Date()
    )

    static let longAssistantMessage = OpenClawMessage(
        role: .assistant,
        content: """
        Based on the Montana DEQ database, here are the currently active sapphire mining claims in the Philipsburg area:

        1. **Gem Mountain** — Commercial operation, open to public
        2. **Spokane Bar** — Private claim, Est. 1895
        3. **Rock Creek** — Active exploration permit
        4. **El Dorado Bar** — Small-scale recreational
        5. **Dry Cottonwood Creek** — Research permit (MSU)

        The Yogo Gulch deposits near Utica are also notable but are ~150 miles north of Philipsburg. Would you like directions to any of these locations?
        """,
        timestamp: Date()
    )
}
