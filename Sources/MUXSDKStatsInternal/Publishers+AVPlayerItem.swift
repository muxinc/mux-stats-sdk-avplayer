import AVFoundation
import Combine
import MuxCore

@available(iOS 15, tvOS 15, *)
extension AVPlayerItem {

    struct StatusFailedError: Error {
        var playerItemError: Error?
    }

    /// Publishes `tracks` once present, failing when overall loading fails
    nonisolated var validTracksPublisher: some Publisher<[AVPlayerItemTrack], StatusFailedError> {
        publisher(for: \.status, options: [.initial])
            .removeDuplicates()
            .map { status in
                lazy var kvo = self.publisher(for: \.tracks, options: [.initial])
                    .removeDuplicates()
                    .setFailureType(to: StatusFailedError.self)

                switch status {
                case .unknown:
                    // tracks should populate before .readyToPlay:
                    return kvo
                        .drop(while: \.isEmpty)
                        .eraseToAnyPublisher()

                case .readyToPlay:
                    // Always valid:
                    return kvo
                        .eraseToAnyPublisher()

                case .failed:
                    fallthrough
                @unknown default:
                    return Fail(error: StatusFailedError(playerItemError: self.error))
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .removeDuplicates()
    }

    nonisolated func timedRenditionInfoPublisher() -> some Publisher<(PlaybackEventTiming, MUXSDKVideoData), StatusFailedError> {
        validTracksPublisher
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
            .removeDuplicates { $0?.trackID == $1?.trackID }
            .flatMap { videoAssetTrack in
                return Future {
                    async let timing = self.currentTiming()
                    guard let videoAssetTrack else {
                        return await (timing, MUXSDKVideoData())
                    }
                    return await (timing, MUXSDKVideoData.makeWithRenditionInfo(track: videoAssetTrack, on: self))
                }
            }
    }

    nonisolated func renditionInfoAndChangeEvents() -> some Publisher<MUXSDKBaseEvent, Never> {
        let timedRenditionInfo = timedRenditionInfoPublisher()
            .catch { _ in
                // Ignore status failed error
                return Empty<(PlaybackEventTiming, MUXSDKVideoData), Never>()
            }

        // Represents an initial data event containing the current state
        let initialEvent = timedRenditionInfo
            .first()
            .map { timing, videoData in
                let event = MUXSDKDataEvent()

                event.videoData = videoData

                return event
            }

#if !targetEnvironment(simulator)
        if #available(iOS 18, tvOS 18, visionOS 2, *) {
            let changeEvents = renditionChangeEventsUsingAVMetrics()
                .catch { error in
                    if !(error is CancellationError) {
                        logger.error("Error from AVMetrics variant switch events: \(error)")
                    }
                    return Empty<MUXSDKRenditionChangeEvent, Never>()
                }

            return Publishers.Concatenate(
                prefix: initialEvent.map { $0 as MUXSDKBaseEvent },
                suffix: changeEvents.map { $0 as MUXSDKBaseEvent })
        }
#endif

        let changeEvents = timedRenditionInfo
            .dropFirst()
            .map { timing, videoData in
                let event = MUXSDKRenditionChangeEvent()

                let playerData = MUXSDKPlayerData()
                playerData.updateWithTiming(timing)
                event.playerData = playerData

                event.videoData = videoData

                return event
            }

        return Publishers.Concatenate(
            prefix: initialEvent.map { $0 as MUXSDKBaseEvent },
            suffix: changeEvents.map { $0 as MUXSDKBaseEvent })
    }

    @available(iOS 18, tvOS 18, visionOS 2, *)
    nonisolated func renditionChangeEventsUsingAVMetrics() -> some Publisher<MUXSDKRenditionChangeEvent, Error> {
        metrics(forType: AVMetricPlayerItemVariantSwitchEvent.self)
            .filter(\.didSucceed)
            .map { metricEvent in
                let timing = await PlaybackEventTiming(variantSwitchEvent: metricEvent, on: self)
                return (metricEvent, timing)
            }
            .publisher
            .map { (metricEvent, timing) in
                let muxEvent = MUXSDKRenditionChangeEvent()

                let playerData = MUXSDKPlayerData()
                playerData.updateWithTiming(timing)
                muxEvent.playerData = playerData

                let videoData = MUXSDKVideoData()
                videoData.updateWithAssetVariant(metricEvent.toVariant)
#if compiler(>=6.2)
                if #available(iOS 26, tvOS 26, visionOS 26, *) {
                    videoData.updateWithMediaRendition(metricEvent.videoRendition)
                }
#endif
                muxEvent.videoData = videoData

                return muxEvent
            }
    }

#if !targetEnvironment(simulator)
    @available(iOS 18, tvOS 18, visionOS 2, *)
    nonisolated func requestBandwidthEvents() -> some Publisher<MUXSDKRequestBandwidthEvent, Never> {
        Publishers.Merge3(
            metrics(forType: AVMetricHLSPlaylistRequestEvent.self)
                .publisher // manifest requests
                .compactMap { MUXSDKRequestBandwidthEvent(event: $0) },
            metrics(forType: AVMetricHLSMediaSegmentRequestEvent.self)
                .publisher  // audio/video/media requests
                .compactMap { MUXSDKRequestBandwidthEvent(event: $0) },
            metrics(forType: AVMetricContentKeyRequestEvent.self)
                .publisher  // encryption requests
                .compactMap { MUXSDKRequestBandwidthEvent(event: $0) }
        )
        .catch { error in
            if !(error is CancellationError) {
                logger.error(
                    "Error from AVMetrics Bandwidth events: \(error)"
                )
            }
            return Empty<MUXSDKRequestBandwidthEvent, Never>()
        }
    }
#endif
}

@available(iOS 15, tvOS 15, *)
extension AVPlayerItem.StatusFailedError: CustomNSError {
    var errorUserInfo: [String : Any] {
        var userInfo = [String: Any]()
        userInfo[NSUnderlyingErrorKey] = playerItemError as NSError?
        return userInfo
    }
}
