import AVFoundation
import Combine
@preconcurrency import MuxCore
@testable import MUXSDKStatsInternal
import Testing

struct MainQueueEventCreationTests {

    /// Observe directly at each producer, before PlayerMonitor's final delivery hop.
    @available(iOS 15, tvOS 15, *)
    @Test func eventsAreCreatedOnMainQueue() async throws {
        let player = AVPlayer()
        player.isMuted = true
        let playerItem = AVPlayerItem(url: bipBopExampleURL)

        // These assertions cover emission; the rendition constructor also asserts main-queue use.
        let events = playerItem.renditionChangeEvents().map { ($0.getType() ?? "", Thread.isMainThread) }
            .merge(with: playerItem.textTrackChangeEvents().map { ($0.getType() ?? "", Thread.isMainThread) })
            .merge(with: playerItem.audioTrackChangeEvents().map { ($0.getType() ?? "", Thread.isMainThread) })
            .buffer(size: 10, prefetch: .byRequest, whenFull: .dropOldest)
            .values

        player.replaceCurrentItem(with: playerItem)
        player.play()

        let expectedTypes: Set = [
            MUXSDKPlaybackEventRenditionChangeEventType,
            MUXSDKPlaybackEventTextTrackChangeEventType,
            MUXSDKPlaybackEventAudioTrackChangeEventType,
        ]

        let createdOnMainQueueByType = try await withTimeout(seconds: 30) {
            var createdOnMainQueueByType = [String: Bool]()
            for await (type, isMainThread) in events {
                createdOnMainQueueByType[type, default: true] = createdOnMainQueueByType[type, default: true] && isMainThread
                if expectedTypes.isSubset(of: createdOnMainQueueByType.keys) {
                    break
                }
            }
            return createdOnMainQueueByType
        }

        #expect(Set(createdOnMainQueueByType.keys) == expectedTypes)
        #expect(createdOnMainQueueByType.values.allSatisfy { $0 })
    }
}
