// OpenClawAPI.swift
// OpenClaw watchOS Client
//
// The SSE (Server-Sent Events) network engine.
// Handles both streaming and non-streaming communication with the OpenClaw Gateway.
// Uses modern async/await and AsyncThrowingStream for efficient memory usage on the S10 chip.

import Foundation

final class OpenClawAPI: Sendable {
    static let shared = OpenClawAPI()

    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - Streaming Chat Completion (Primary Method)

    /// Streams a chat completion from the OpenClaw Gateway using SSE.
    /// Each yielded `String` is a text fragment (delta) from the assistant's response.
    ///
    /// - Parameters:
    ///   - messages: The full conversation history to send.
    /// - Returns: An `AsyncThrowingStream` of text deltas.
    func streamChat(
        messages: [ChatCompletionRequest.ChatRequestMessage]
    ) async throws -> AsyncThrowingStream<String, Error> {

        let request = try buildRequest(messages: messages, stream: true)

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: OpenClawError.invalidResponse)
                        return
                    }

                    guard httpResponse.statusCode == 200 else {
                        let errorMessage = "Gateway returned HTTP \(httpResponse.statusCode)"
                        if httpResponse.statusCode == 401 {
                            continuation.finish(throwing: OpenClawError.authenticationFailed)
                        } else {
                            continuation.finish(throwing: OpenClawError.httpError(
                                statusCode: httpResponse.statusCode,
                                message: errorMessage
                            ))
                        }
                        return
                    }

                    // Parse the SSE text/event-stream line by line
                    for try await line in bytes.lines {
                        // SSE format: lines prefixed with "data: "
                        guard line.hasPrefix("data: ") else { continue }

                        let payload = String(line.dropFirst(6))

                        // "[DONE]" signals end of stream
                        if payload == "[DONE]" {
                            continuation.finish()
                            return
                        }

                        // Parse the JSON chunk
                        guard let data = payload.data(using: .utf8) else { continue }

                        do {
                            let chunk = try self.decoder.decode(ChatCompletionChunk.self, from: data)
                            if let content = chunk.choices.first?.delta.content {
                                continuation.yield(content)
                            }

                            // Check for finish_reason
                            if let finishReason = chunk.choices.first?.finishReason,
                               finishReason == "stop" {
                                continuation.finish()
                                return
                            }
                        } catch {
                            // Skip malformed chunks rather than crashing
                            #if DEBUG
                            print("⚠️ Skipped malformed SSE chunk: \(payload)")
                            #endif
                        }
                    }

                    // Stream ended naturally
                    continuation.finish()

                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: OpenClawError.networkError(error))
                }
            }

            // Support cancellation
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Non-Streaming Chat Completion (Fallback)

    /// Sends a non-streaming chat completion request.
    /// Useful for quick commands where you don't need real-time token display.
    ///
    /// - Parameters:
    ///   - messages: The conversation history.
    /// - Returns: The complete assistant response as a `String`.
    func sendChat(
        messages: [ChatCompletionRequest.ChatRequestMessage]
    ) async throws -> String {

        let request = try buildRequest(messages: messages, stream: false)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenClawError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw OpenClawError.authenticationFailed
            }
            throw OpenClawError.httpError(
                statusCode: httpResponse.statusCode,
                message: String(data: data, encoding: .utf8)
            )
        }

        let decoded = try decoder.decode(ChatCompletionResponse.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }

    // MARK: - Gateway Health Check

    /// Pings the Gateway to verify connectivity.
    /// Returns `true` if the Gateway is reachable and responding.
    func pingGateway() async -> Bool {
        guard let url = URL(string: "\(APIConstants.baseUrl)/health") else { return false }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.httpMethod = "GET"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Private Helpers

    private func buildRequest(
        messages: [ChatCompletionRequest.ChatRequestMessage],
        stream: Bool
    ) throws -> URLRequest {

        guard let url = URL(string: "\(APIConstants.baseUrl)/v1/chat/completions") else {
            throw OpenClawError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConstants.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("OpenClawWatch/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = stream
            ? APIConstants.streamTimeoutSeconds
            : APIConstants.requestTimeoutSeconds

        let requestBody = ChatCompletionRequest(
            model: APIConstants.model,
            messages: messages,
            stream: stream
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        return request
    }
}
