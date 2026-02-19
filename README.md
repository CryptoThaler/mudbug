# 🦞 mudbug — OpenClaw watchOS Client

> **Liquid Glass Watch • iOS • OpenClaw Interface**

A thin Gateway client for [OpenClaw](https://github.com/nicepkg/openclaw) on **watchOS 12**, targeting the **Apple Watch Series 11**. One tap on your wrist to command your autonomous AI agent.

---

## 🏗️ Architecture — Hybrid Client

mudbug uses a **hybrid architecture**: standalone HTTP/SSE to the Gateway for active chat, plus **WatchConnectivity** (WCSession) as a background relay from the paired iPhone for push-style notifications.

```
┌─────────────┐       HTTPS/SSE        ┌──────────────────┐       TDLib        ┌──────────┐
│  Apple Watch │  ──────────────────▶  │  OpenClaw Gateway │  ──────────────▶  │ Telegram │
│  (mudbug)    │  ◀──────────────────  │  :18789           │  ◀──────────────  │ Servers  │
└──────┬──────┘    text/event-stream   └──────┬───────────┘                    └──────────┘
       │                                      │
       │  WCSession (background relay)        │ Operator Protocol
       │  ◀────────────────────────────       │
       │                               ┌──────┴───────┐
       └───────────────────────────────│  iPhone App  │
                                       └──────────────┘
```

### Why Gateway, not standalone TDLib?

| Criteria | Gateway (mudbug) | Standalone TDLib |
|----------|:---:|:---:|
| Binary size | ~5 MB | ~300 MB |
| Battery impact | Minimal | High |
| RAM pressure | Low | > 500 MB |
| Auth complexity | Bearer token | QR code sync |
| Supports all Skills | ✅ | ❌ |
| Requires server | ✅ | ❌ |

---

## 📂 Project Structure

```
OpenClawWatch/
├── App/
│   ├── OpenClawApp.swift               # Entry point + WCSession init
│   └── ComplicationBundle.swift        # Widget extension entry
├── Features/
│   ├── Chat/
│   │   ├── ChatView.swift              # Liquid Glass chat UI
│   │   ├── ChatViewModel.swift         # Business logic & streaming
│   │   ├── MessageBubble.swift         # Glass bubble component
│   │   └── SettingsView.swift          # Gateway config & diagnostics
│   └── Complication/
│       └── QuickActionComplication.swift # Watch face widget
├── Core/
│   ├── Network/
│   │   ├── OpenClawAPI.swift           # SSE streaming engine
│   │   ├── APIConstants.swift.sample   # Config template (committed)
│   │   └── APIConstants.swift          # Your secrets (gitignored)
│   ├── Connectivity/
│   │   └── WatchConnectivityReceiver.swift # iPhone → Watch relay
│   ├── Models/
│   │   └── OpenClawModels.swift        # Protocol models
│   ├── Persistence/
│   │   └── ConversationStore.swift     # UserDefaults chat history
│   └── Haptics/
│       └── HapticManager.swift         # Tactile feedback
└── Preview Content/
    └── PreviewData.swift               # Mock data for previews
```

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 26** (or later) with watchOS 12 SDK
- An **OpenClaw Gateway** running and reachable (local network, Tailscale, or public URL)
- Gateway HTTP API enabled in `openclaw.json`:
  ```json
  {
    "gateway": {
      "http": {
        "endpoints": {
          "chatCompletions": { "enabled": true }
        }
      }
    }
  }
  ```

### Setup

1. **Clone the repo:**
   ```bash
   git clone https://github.com/CryptoThaler/mudbug.git
   cd mudbug
   ```

2. **Configure your Gateway credentials:**
   ```bash
   cp OpenClawWatch/Core/Network/APIConstants.swift.sample \
      OpenClawWatch/Core/Network/APIConstants.swift
   ```
   Edit `APIConstants.swift` with your Gateway URL and bearer token.

3. **Open in Xcode:**
   ```bash
   open OpenClawWatch.xcodeproj
   ```
   Or create a new watchOS project in Xcode and drag in the `OpenClawWatch/` source folder.

4. **Build & Run:**
   - Select the **Watch App** scheme
   - Target: **Apple Watch Series 11 (45mm) Simulator** or your physical Watch
   - Press **⌘R**

---

## ⌚ Features

### 🪟 Liquid Glass Interface
All message bubbles and the input bar use `ultraThinMaterial` with gradient overlays, inner stroke borders for glass-edge light refraction, and soft shadows for depth. Dark gradient background for maximum contrast.

### 💬 Streaming Chat
Real-time token-by-token display using `URLSession.bytes(for:)` and `AsyncThrowingStream`. See the AI "type" on your wrist.

### 🧠 Animated Thinking Dots
Bouncing dot animation in OpenClaw's signature orange while the agent processes your request — replaces the standard ProgressView.

### 📲 WatchConnectivity (iPhone Relay)
Receives background push-style notifications from the paired iPhone via `WCSession`. Ported from the [official OpenClaw WatchExtension](https://github.com/openclaw/openclaw/tree/main/apps/ios/WatchExtension) with dedup and chat integration.

### 📳 Haptic Feedback
- **Click** when you send a message
- **Success** when the AI finishes responding
- **Failure** on network errors

### ⌚ Watch Face Complication
One-tap complication in circular, rectangular, corner, and inline styles. Shows the last assistant message preview and opens directly to chat.

### 💾 Conversation Persistence
Last 50 messages stored in UserDefaults so your chat survives app suspension and relaunch from the Watch Dock.

### 🔄 Error Recovery
Automatic retry support, connection status banner, and Gateway health check from Settings.

---

## 🔑 Security

- `APIConstants.swift` is **gitignored** — your token never leaves your machine
- The `.sample` template is committed so collaborators know the expected structure
- All connections use HTTPS with bearer token auth
- Consider using a proper cert (Let's Encrypt / Cloudflare) rather than self-signed

---

## 🛑 The "Push" Problem (Mitigated)

OpenClaw Gateway doesn't natively send Apple Push Notifications. mudbug mitigates this via:

1. **WatchConnectivity** — The iPhone OpenClaw app relays notifications to the Watch via `WCSession` even when mudbug is backgrounded
2. **Telegram fallback** — Let your agent send results to your Telegram DM; the Telegram system notification hits your Watch

---

## 📋 Roadmap

- [x] **v1.0** — Core chat with streaming SSE
- [x] **v1.1** — Liquid Glass interface
- [x] **v1.2** — WatchConnectivity hybrid relay
- [ ] **v1.3** — HealthKit integration (workout context for the agent)
- [ ] **v1.4** — Siri Shortcuts / App Intents integration
- [ ] **v2.0** — Push notification relay via CloudKit
- [ ] **v2.1** — Multi-conversation support with SwiftData
- [ ] **v2.2** — ClawHub skill browser on the wrist

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/health-kit-integration`)
3. Commit your changes (`git commit -m 'Add HealthKit context to chat'`)
4. Push to the branch (`git push origin feature/health-kit-integration`)
5. Open a Pull Request

---

## 📄 License

This project is open source. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>🦞 Built for the wrist. Powered by OpenClaw.</strong><br>
  <em>mudbug — because crawdads are just lobsters with ambition.</em>
</p>
