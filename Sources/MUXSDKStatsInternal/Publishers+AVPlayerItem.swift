import AVFoundation
import Combine
import MuxCore

@available(iOS 15, tvOS 15, *)
extension AVPlayerItem {

    struct StatusFailedError: Error {
    }

    /// Publishes `tracks` once loaded
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
                    return Fail(error: StatusFailedError())
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .removeDuplicates()
    }

    nonisolated func timedRenditionInfoPublisher() -> some Publisher<(PlaybackEventTiming, Future<MUXSDKVideoData, Never>), StatusFailedError> {

        return validTracksPublisher
            // @MainActor isolated: AVPlayerItemTrack (and therefore its assetTrack property)
            .receive(on: ImmediateIfOnMainQueueScheduler.shared)
            .map { tracks in
                MainActor.assumeIsolated {
                    tracks.lazy
                        .compactMap(\.assetTrack)
                        .first { $0.mediaType == .video }
                }
            }
            .removeDuplicates { $0?.trackID == $1?.trackID }
            .map { videoAssetTrack in
                // capture timing immediately
                let timing = PlaybackEventTiming(playerItem: self)

                let videoDataFuture = Future {
                    await MUXSDKVideoData.renditionVideoData(for: self, track: videoAssetTrack)
                }

                return (timing, videoDataFuture)
            }
    }

    @available(iOS 18, tvOS 18, *)
    nonisolated func renditionChangeEventsUsingAVMetrics(playerData: some Publisher<MUXSDKPlayerData, Never>) -> some Publisher<MUXSDKBaseEvent, Never> {

        return metrics(forType: AVMetricPlayerItemVariantSwitchEvent.self)
            .filter(\.didSucceed)
            .map { event in (PlaybackEventTiming(variantSwitchEvent: event, on: self), event) }
            .publisher
            .catch { _ in Empty() }
            .combineLatest(playerData)
            .map { timingAndMetricEvent, _playerData in
                let timing = timingAndMetricEvent.0
                let metricEvent = timingAndMetricEvent.1
                let muxEvent = MUXSDKRenditionChangeEvent()

                let playerData = MUXSDKPlayerData(copying: _playerData)
                playerData.updateWithTiming(timing)
                muxEvent.playerData = playerData

                let videoData = MUXSDKVideoData()
                videoData.updateWithAssetVariant(metricEvent.toVariant)
                muxEvent.videoData = videoData

                return muxEvent
            }
    }

    nonisolated func renditionInfoAndChangeEvents(playerData: some Publisher<MUXSDKPlayerData, Never>) -> some Publisher<MUXSDKBaseEvent, Never> {
        let timedEvents = timedRenditionInfoPublisher()

        let initialEvent: some Publisher<MUXSDKBaseEvent, Never> = timedEvents
            .first()
            .catch { error in
                return Empty()
            }
            .flatMap { timing, videoDataFuture in
                videoDataFuture
                    .map { videoData in
                        let event = MUXSDKDataEvent()

                        event.videoData = videoData

                        return event as MUXSDKBaseEvent
                    }
            }

#if !targetEnvironment(simulator)
        if #available(iOS 18, tvOS 18, *) {
            return Publishers.Concatenate(prefix: initialEvent, suffix: renditionChangeEventsUsingAVMetrics(playerData: playerData))
        }
#endif

        let changeEvents: some Publisher<MUXSDKBaseEvent, Never> = timedEvents.dropFirst()
            .catch { _ in Empty() }
            .combineLatest(playerData)
            .flatMap { timedVideoData, _playerData in
                let timing = timedVideoData.0
                let videoDataFuture = timedVideoData.1
                let playerData = MUXSDKPlayerData(copying: _playerData)
                
                playerData.updateWithTiming(timing)

                return videoDataFuture
                    .map { videoData in
                        let event = MUXSDKRenditionChangeEvent()
                        event.playerData = playerData
                        event.videoData = videoData

                        return event as MUXSDKBaseEvent
                    }
            }

        return Publishers.Concatenate(prefix: initialEvent, suffix: changeEvents)
    }
}
