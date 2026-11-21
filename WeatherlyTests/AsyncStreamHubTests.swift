import Foundation
import Testing
@testable import Weatherly

@MainActor
struct AsyncStreamHubTests {
    @Test func `when multiple streams subscribe each receives every published element`() async {
        let hub = AsyncStreamHub<Int>()
        let firstStream = hub.makeStream(bufferingPolicy: .unbounded)
        let secondStream = hub.makeStream(bufferingPolicy: .unbounded)
        var firstIterator = firstStream.makeAsyncIterator()
        var secondIterator = secondStream.makeAsyncIterator()

        hub.yield(1)
        hub.yield(2)

        #expect(await firstIterator.next() == 1)
        #expect(await firstIterator.next() == 2)
        #expect(await secondIterator.next() == 1)
        #expect(await secondIterator.next() == 2)
    }

    @Test func `when a stream requests replay it receives the latest published element`() async {
        let hub = AsyncStreamHub<Int>()
        hub.yield(1)
        hub.yield(2)

        let stream = hub.makeStream(replayLatest: true)
        var iterator = stream.makeAsyncIterator()

        #expect(await iterator.next() == 2)
    }

    @Test func `when replaying a published nil optional element the stream receives nil`() async {
        let hub = AsyncStreamHub<Int?>()
        hub.yield(nil)

        let stream = hub.makeStream(replayLatest: true)
        var iterator = stream.makeAsyncIterator()
        let receivedElement = await iterator.next()

        if let receivedElement {
            #expect(receivedElement == nil)
        } else {
            Issue.record("Expected the stream to replay a published nil element.")
        }
    }

    @Test func `when the hub finishes active streams their iterators end`() async {
        let hub = AsyncStreamHub<Int>()
        let stream = hub.makeStream()
        var iterator = stream.makeAsyncIterator()

        hub.finish()

        #expect(await iterator.next() == nil)
    }
}
