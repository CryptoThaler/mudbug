// QuickActionComplication.swift
// OpenClaw watchOS Client
//
// WidgetKit-based complication for the watch face.
// One tap opens the app directly to the dictation/chat input screen.
// Supports multiple complication families for different watch face styles.

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct OpenClawTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> OpenClawEntry {
        OpenClawEntry(date: Date(), lastMessage: "Ask OpenClaw…")
    }

    func getSnapshot(in context: Context, completion: @escaping (OpenClawEntry) -> Void) {
        let entry = OpenClawEntry(date: Date(), lastMessage: "Ask OpenClaw…")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OpenClawEntry>) -> Void) {
        // Load the last assistant message for display
        let messages = ConversationStore.shared.load()
        let lastAI = messages.last(where: { $0.role == .assistant })?.content ?? "Ask OpenClaw…"
        let truncated = String(lastAI.prefix(60))

        let entry = OpenClawEntry(date: Date(), lastMessage: truncated)
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct OpenClawEntry: TimelineEntry {
    let date: Date
    let lastMessage: String
}

// MARK: - Complication Views

struct OpenClawComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: OpenClawEntry

    private let clawOrange = Color(red: 1.0, green: 0.45, blue: 0.1)

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryCorner:
            cornerView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    // Small circular complication (shows just the claw icon)
    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Text("🦞")
                .font(.system(size: 22))
        }
    }

    // Rectangular complication (shows last message preview)
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text("🦞")
                    .font(.system(size: 10))
                Text("OpenClaw")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(clawOrange)
            }
            Text(entry.lastMessage)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    // Corner complication
    private var cornerView: some View {
        Text("🦞")
            .font(.system(size: 20))
            .widgetLabel {
                Text("OpenClaw")
            }
    }

    // Inline complication
    private var inlineView: some View {
        Text("🦞 OpenClaw")
            .font(.system(size: 12, weight: .medium, design: .rounded))
    }
}

// MARK: - Widget Configuration

struct OpenClawComplication: Widget {
    let kind: String = "OpenClawQuickAction"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OpenClawTimelineProvider()) { entry in
            OpenClawComplicationView(entry: entry)
        }
        .configurationDisplayName("OpenClaw")
        .description("Quick access to your AI agent.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

// MARK: - Preview

#Preview(as: .accessoryRectangular) {
    OpenClawComplication()
} timeline: {
    OpenClawEntry(date: Date(), lastMessage: "The weather in Bozeman is currently 28°F with clear skies.")
    OpenClawEntry(date: Date(), lastMessage: "Ask OpenClaw…")
}
