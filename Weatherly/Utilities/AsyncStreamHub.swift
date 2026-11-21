//
//  AsyncStreamHub.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 21/11/2026.
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
/// The stream's element type is exactly `Element`. To represent an absent value,
/// use an optional type as the generic argument, such as `AsyncStreamHub<MyValue?>`.
/// The hub tracks whether it has published a value separately, so it can replay a
/// published `nil` without confusing it with an empty hub.
@MainActor
final class AsyncStreamHub<Element: Sendable> {
    
    // MARK: - Properties
    
    /// Active stream continuations keyed by their unique subscriber identifiers.
    private var continuations: [String: AsyncStream<Element>.Continuation] = [:]

    /// The most recently published element, if one has been published.
    private var latestElement: Element?

    /// Distinguishes an unpublished hub from a hub whose latest optional element is `nil`.
    private var hasLatestElement = false
    
    // MARK: - Init

    /// Creates an empty stream hub.
    init() { }
    
    // MARK: - Methods

    /// Creates an independent asynchronous stream for a consumer.
    ///
    /// The hub registers the stream's continuation and removes it when iteration
    /// terminates. When `replayLatest` is `true`, the stream first receives the most
    /// recently published element, including a published `nil` when `Element` is
    /// optional, if the hub has published a value.
    ///
    /// - Parameters:
    ///   - replayLatest: A Boolean value that indicates whether to yield the latest published element.
    ///   - bufferingPolicy: The policy that controls how this stream buffers elements for its consumer.
    ///     The default policy keeps only the newest element when the consumer falls behind.
    /// - Returns: A new stream that receives future publications independently of other consumers.
    func makeStream(
        replayLatest: Bool = false,
        bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .bufferingNewest(1)
    ) -> AsyncStream<Element> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            let id = UUID().uuidString
            continuations[id] = continuation
            
            if replayLatest, let latestElement, hasLatestElement {
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
    /// If `Element` is optional, pass `nil` to publish an absent value. The hub records
    /// that value and can replay it to a later stream.
    ///
    /// - Parameter element: The element to publish.
    func yield(_ element: Element) {
        latestElement = element
        hasLatestElement = true
        continuations.values.forEach { $0.yield(element) }
    }

    /// Finishes all active streams and removes their continuations.
    ///
    /// The hub retains its latest element, so a stream created afterward can still
    /// receive that element when `replayLatest` is `true`. Finishing current streams
    /// doesn't prevent the hub from creating or publishing to later streams.
    func finish() {
        continuations.values.forEach { $0.finish() }
        continuations.removeAll()
    }

    /// Removes a subscriber after its asynchronous stream terminates.
    ///
    /// - Parameter id: The identifier assigned when the subscriber's stream was created.
    private func removeSubscriber(id: String) {
        continuations[id] = nil
    }
}
