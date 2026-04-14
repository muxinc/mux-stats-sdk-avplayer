import AVFoundation
import Combine
@preconcurrency import MuxCore

@available(iOS 15, tvOS 15, *)
struct RenditionChangeEvents {

    let playerItem: AVPlayerItem

    init(playerItem: AVPlayerItem) {
        self.playerItem = playerItem
    }
}

@available(iOS 15, tvOS 15, *)
extension AVPlayerItem {
    nonisolated func timedRenditionInfoPublisher() -> some Publisher<(PlaybackEventTiming, MUXSDKVideoData), StatusFailedError> {
        tracksReadyToPlayPublisher
            // @MainActor isolated: AVPlayerItemTrack (and therefore its assetTrack property)
            .receive(on: ImmediateIfOnMainQueueScheduler.shared)
            .map { (tracks: [AVPlayerItemTrack]) -> AVAssetTrack? in
                // work around Sendable requirement on assumeIsolated
                nonisolated(unsafe) var videoAssetTrack: AVAssetTrack? = nil
                MainActor.assumeIsolated {
                    videoAssetTrack = tracks.lazy
                        .compactMap(\.assetTrack)
                        .first { $0.mediaType == .video }
                }
                return videoAssetTrack
            }
        // AVPlayerItemTracks and AVAssetTracks are replaced for various reasons during
        // playback, during seeking for example. While the following will unique these
        // objects, a new object here may still refer to the same rendition:
            .removeDuplicates()
            .flatMap(maxPublishers: .max(1)) { videoAssetTrack in
                // Boost priority as this kicks off a chain of timing-sensitive operations
                return Future(priority: .userInitiated) {
                    async let timing = self.currentTiming()
                    guard let videoAssetTrack else {
                        return await (timing, MUXSDKVideoData())
                    }
                    return await (timing, MUXSDKVideoData.makeWithRenditionInfo(track: videoAssetTrack, on: self))
                }
            }
        // Determine uniqueness (and therefore rendition changes) based on fully populated
        // video data:
            .removeDuplicates { timedInfoA, timedInfoB in
                let (_, videoDataA) = timedInfoA
                let (_, videoDataB) = timedInfoB
                let queryDictA = videoDataA.toQuery() as NSDictionary
                let queryDictB = videoDataB.toQuery() as NSDictionary
                return queryDictA == queryDictB
            }
    }

    nonisolated func renditionChangeEvents() -> some Publisher<MUXSDKRenditionChangeEvent, Never> {
        let changeEventsUsingTracks = timedRenditionInfoPublisher()
            .catch { _ in
                // Ignore status failed error
                return Empty<(PlaybackEventTiming, MUXSDKVideoData), Never>()
            }
            .map { timing, videoData in
                let event = MUXSDKRenditionChangeEvent()

                let playerData = MUXSDKPlayerData()
                playerData.updateWithTiming(timing)
                event.playerData = playerData

                event.videoData = videoData

                return event
            }

#if !targetEnvironment(simulator)
        if #available(iOS 18, tvOS 18, visionOS 2, *) {
            let remainingEvents = renditionChangeEventsAfterInitialEvent()
                .catch { error in
                    if !(error is CancellationError) {
                        logger.error("Error from AVMetrics variant switch events: \(error)")
                    }
                    return Empty<MUXSDKRenditionChangeEvent, Never>()
                }

            return Publishers.Concatenate(
                prefix: changeEventsUsingTracks.first(),
                suffix: remainingEvents)
        }
#endif

        return changeEventsUsingTracks
    }

    @available(iOS 18, tvOS 18, visionOS 2, *)
    nonisolated func renditionChangeEventsAfterInitialEvent() -> some Publisher<MUXSDKRenditionChangeEvent, Error> {
        metrics(forType: AVMetricPlayerItemVariantSwitchEvent.self)
            .filter(\.didSucceed)
            .map { metricEvent in
                let muxEvent = MUXSDKRenditionChangeEvent()

                let playerData = MUXSDKPlayerData()
                let timing = await PlaybackEventTiming(variantSwitchEvent: metricEvent, on: self)
                playerData.updateWithTiming(timing)
                muxEvent.playerData = playerData

                let videoData = MUXSDKVideoData()
                videoData.updateWithAssetVariant(metricEvent.toVariant)
                muxEvent.videoData = videoData

                return muxEvent
            }
            .publisher
    }
}
