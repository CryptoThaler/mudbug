// OpenClawModels.swift
// OpenClaw watchOS Client
// Core data models for the OpenClaw Gateway protocol

import Foundation

// MARK: - Message Role

enum OpenClawRole: String, Codable, Equatable {
    case user
    case assistant
    case system
    case tool
}

// MARK: - Chat Message

struct OpenClawMessage: Identifiable, Equatable {
    let id: UUID
    let role: OpenClawRole
    var content: String
    var isThinking: Bool
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: OpenClawRole,
        content: String,
        isThinking: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.isThinking = isThinking
        self.timestamp = timestamp
    }

    static func == (lhs: OpenClawMessage, rhs: OpenClawMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.role == rhs.role &&
        lhs.content == rhs.content &&
        lhs.isThinking == rhs.isThinking
    }
}

// MARK: - API Request Models

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatRequestMessage]
    let stream: Bool

    struct ChatRequestMessage: Codable {
        let role: String
        let content: String
    }
}

// MARK: - API Response Models (Non-Streaming)

struct ChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?

    struct Choice: Codable {
        let index: Int
        let message: ResponseMessage
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }

    struct ResponseMessage: Codable {
        let role: String
        let content: String?
    }

    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// MARK: - Streaming Response Models (SSE Chunks)

struct ChatCompletionChunk: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [StreamChoice]

    struct StreamChoice: Codable {
        let index: Int
        let delta: Delta
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index, delta
            case finishReason = "finish_reason"
        }
    }

    struct Delta: Codable {
        let role: String?
        let content: String?
    }
}

// MARK: - Gateway Status

struct GatewayStatus: Codable {
    let status: String
    let version: String?
    let uptime: Double?
}

// MARK: - Error Models

enum OpenClawError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case streamParsingError(String)
    case authenticationFailed
    case gatewayUnreachable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Gateway URL configuration."
        case .invalidResponse:
            return "Received an invalid response from the Gateway."
        case .httpError(let code, let msg):
            return "HTTP \(code): \(msg ?? "Unknown error")"
        case .decodingError(let err):
            return "Failed to decode response: \(err.localizedDescription)"
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        case .streamParsingError(let detail):
            return "Stream parsing error: \(detail)"
        case .authenticationFailed:
            return "Authentication failed. Check your bearer token."
        case .gatewayUnreachable:
            return "Cannot reach OpenClaw Gateway. Verify the URL and ensure the server is running."
        }
    }
}
