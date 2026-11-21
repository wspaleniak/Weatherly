//
//  AsyncStreamHub.swift
//  Weatherly
//
//  Created by Codex on 21/11/2026.
//

import Foundation

/// Broadcasts published elements to independent asynchronous stream consumers.
///
/// Create one stream for each consumer with ``makeStream(replayLatest:bufferingPolicy:)``.
/// Each active stream receives every published element, subject to its buffering policy.
/// The hub retains the latest published element so a new stream can optionally receive it.
///
/// The hub is isolated to the main actor to serialize subscriber registration,
/// publication, and termination.
///
/// - Note: The produced streams always contain optional elements. This lets the hub
///   publish `nil` as a value while tracking separately whether it has published anything.
@MainActor
final class AsyncStreamHub<Element: Sendable> {
    private var continuations: [String: AsyncStream<Element?>.Continuation] = [:]
    private var latestElement: Element?
    private var hasLatestElement = false

    /// Creates an empty stream hub.
    init() { }

    /// Creates an independent asynchronous stream for a consumer.
    ///
    /// The hub registers the stream's continuation and removes it when iteration
    /// terminates. When `replayLatest` is `true`, the stream first receives the most
    /// recently published element, including `nil`, if the hub has published a value.
    ///
    /// - Parameters:
    ///   - replayLatest: A Boolean value that indicates whether to yield the latest published element.
    ///   - bufferingPolicy: The policy that controls how this stream buffers elements for its consumer.
    ///     The default policy keeps only the newest element when the consumer falls behind.
    /// - Returns: A new stream that receives future publications independently of other consumers.
    func makeStream(
        replayLatest: Bool = false,
        bufferingPolicy: AsyncStream<Element?>.Continuation.BufferingPolicy = .bufferingNewest(1)
    ) -> AsyncStream<Element?> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            let id = UUID().uuidString
            continuations[id] = continuation
            
            if replayLatest, hasLatestElement {
                continuation.yield(latestElement)
            }
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.removeSubscriber(id: id)
                }
            }
        }
    }

    /// Publishes an element to every active consumer and records it for optional replay.
    ///
    /// The hub accepts `nil` as a published element. A later stream created with
    /// `replayLatest` set to `true` receives that `nil` value if it was the latest
    /// publication.
    ///
    /// - Parameter element: The optional element to publish.
    func yield(_ element: Element?) {
        latestElement = element
        hasLatestElement = true
        continuations.values.forEach { $0.yield(element) }
    }

    /// Finishes all active streams and removes their continuations.
    ///
    /// The hub retains its latest element, so a stream created afterward can still
    /// receive that element when `replayLatest` is `true`.
    func finish() {
        continuations.values.forEach { $0.finish() }
        continuations.removeAll()
    }

    private func removeSubscriber(id: String) {
        continuations[id] = nil
    }
}
