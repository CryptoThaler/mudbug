// VoiceEngine.swift
// MudBug watchOS Client
//
// Text-to-speech for reading responses aloud.
// Uses AVSpeechSynthesizer with a warm, slightly fast voice.

import AVFoundation

@MainActor
final class VoiceEngine {
    static let shared = VoiceEngine()

    private let synth = AVSpeechSynthesizer()
    private(set) var isSpeaking = false

    private init() {}

    func speak(_ text: String) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.1
        utterance.pitchMultiplier = 1.05
        utterance.volume = 0.9
        synth.speak(utterance)
        isSpeaking = true
        HapticManager.voiceStart()
    }

    func stop() {
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    func toggle(_ text: String) {
        if synth.isSpeaking {
            stop()
            HapticManager.voiceStop()
        } else {
            speak(text)
        }
    }
}
