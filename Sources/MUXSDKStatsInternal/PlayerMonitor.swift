public import AVFoundation
import Combine
@preconcurrency public import MuxCore


@available(iOS 15, tvOS 15, *)
@objc(MUXSDKPlayerMonitor)
public final class PlayerMonitor: NSObject {

    private var cancellable: AnyCancellable?

    private var isCancelledFlag: Bool = false
    private let isCancelledLock =  NSLock()

    private nonisolated var isCancelled: Bool {
        isCancelledLock.withLock { isCancelledFlag }
    }

    /// Cancels future events and makes a best-effort attempt to cancel any in-flight onEvent callback
    @objc public nonisolated func cancel() {
        isCancelledLock.withLock {
            isCancelledFlag = true
        }
        cancellable?.cancel()
    }

    @objc public init(player: AVPlayer, onEvent: @Sendable @escaping @MainActor (MUXSDKBaseEvent) -> Void) {
        super.init()

        let allEvents = player.publisher(for: \.currentItem, options: [.initial])
            .removeDuplicates()
            .map { (playerItem: AVPlayerItem?) -> AnyPublisher<MUXSDKBaseEvent, Never> in
                guard let playerItem else {
                    return Empty().eraseToAnyPublisher()
                }

                let merged = playerItem.renditionChangeEvents().map { $0 as MUXSDKBaseEvent }
                    .merge(with: playerItem.textTrackChangeEvents().map { $0 as MUXSDKBaseEvent })
                    .merge(with: playerItem.audioTrackChangeEvents().map { $0 as MUXSDKBaseEvent })

#if !targetEnvironment(simulator)
                if #available(iOS 18, tvOS 18, visionOS 2, *) {
                    return merged
                        .merge(with: playerItem.requestBandwidthEvents().map { $0 as MUXSDKBaseEvent })
                        .eraseToAnyPublisher()
                }
#endif

                return merged.eraseToAnyPublisher()
            }
            .switchToLatest()

        cancellable = allEvents
            .subscribe(on: ImmediateIfOnMainQueueScheduler.shared)
            .receive(on: ImmediateIfOnMainQueueScheduler.shared)
            .sink(receiveValue: { [weak self] event in
                guard self?.isCancelled == false else {
                    return
                }
                MainActor.assumeIsolated {
                    onEvent(event)
                }
            })
    }
}
