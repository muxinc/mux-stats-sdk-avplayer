public import AVFoundation
import Combine
@preconcurrency public import MuxCore


@available(iOS 15, tvOS 15, *)
@objc(MUXSDKPlayerMonitor)
public final class PlayerMonitor: NSObject {

    private let subscriptionWrapper = SubscriptionWrapper()

    /// Cancels future events and makes a best-effort attempt to cancel any in-flight onEvent callback
    @objc public nonisolated func cancel() {
        subscriptionWrapper.cancel()
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

        let handle = allEvents
            .subscribe(on: ImmediateIfOnMainQueueScheduler.shared)
            .receive(on: ImmediateIfOnMainQueueScheduler.shared)
            .sink(receiveValue: { [weak self] event in
                guard self?.subscriptionWrapper.isCancelled == false else {
                    return
                }
                MainActor.assumeIsolated {
                    onEvent(event)
                }
            })

        subscriptionWrapper.setOrCancelSubscriptionHandle(handle)
    }
}

@available(iOS 15, tvOS 15, *)
extension PlayerMonitor {
    // Stand-in for OSAllocatedUnfairLock (unavailable on iOS 15)
    private final class SubscriptionWrapper {
        private let lock = NSLock()
        // guarded by lock
        private var subscriptionHandle: AnyCancellable?
        // guarded by lock
        private var isCancelledFlag: Bool = false

        func setOrCancelSubscriptionHandle(_ handle: AnyCancellable) {
            let toCancel: AnyCancellable? = lock.withLock {
                guard isCancelledFlag == false else {
                    return handle
                }
                return exchange(&subscriptionHandle, with: handle)
            }
            toCancel?.cancel()
        }

        func cancel() {
            let toCancel = lock.withLock {
                isCancelledFlag = true
                return exchange(&subscriptionHandle, with: nil)
            }
            toCancel?.cancel()
        }

        var isCancelled: Bool {
            lock.withLock { isCancelledFlag }
        }
    }
}
