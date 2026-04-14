import AVFoundation
import Combine
@preconcurrency import MuxCore

@available(iOS 15, tvOS 15, *)
extension AVPlayerItem {

    struct StatusFailedError: Error {
        var playerItemError: Error?
    }

    /// Publishes `tracks` once initial loading completes, failing when overall loading fails
    nonisolated var tracksReadyToPlayPublisher: some Publisher<[AVPlayerItemTrack], StatusFailedError> {
        publisher(for: \.status, options: [.initial])
            .removeDuplicates()
            .map { status in
                switch status {
                case .unknown:
                    return Empty<[AVPlayerItemTrack], StatusFailedError>()
                        .eraseToAnyPublisher()

                case .readyToPlay:
                    return self.publisher(for: \.tracks, options: [.initial])
                        .removeDuplicates()
                        .setFailureType(to: StatusFailedError.self)
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
