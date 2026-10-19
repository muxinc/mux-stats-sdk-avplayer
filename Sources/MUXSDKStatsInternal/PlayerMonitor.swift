public import AVFoundation
import Combine
@preconcurrency public import MuxCore


@available(iOS 15, tvOS 15, *)
@objc(MUXSDKPlayerMonitor)
public final class PlayerMonitor: NSObject {

    private let subscriptionWrapper = SubscriptionWrapper()

    /// Marks cancellation immediately so subsequent event checks skip delivery.
    /// A callback that has already passed the check may finish; subscription cleanup
    /// runs on the main queue.
    @objc public nonisolated func cancel() {
        subscriptionWrapper.cancel()
    }

    deinit {
        subscriptionWrapper.cancel()
    }

    @objc public convenience init(player: AVPlayer, onEvent: @Sendable @escaping @MainActor (MUXSDKBaseEvent) -> Void) {
        let allEvents = player.publisher(for: \.currentItem, options: [.initial])
            .removeDuplicates()
            // Serialize item replacement and inner-pipeline cancellation with event delivery.
            .receive(on: ImmediateIfOnMainQueueScheduler.shared)
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

        self.init(events: allEvents.eraseToAnyPublisher(), onEvent: onEvent)
    }

    init(events: AnyPublisher<MUXSDKBaseEvent, Never>, onEvent: @Sendable @escaping @MainActor (MUXSDKBaseEvent) -> Void) {
        super.init()

        let handle = events
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
            Self.cancelOnMainQueue(toCancel)
        }

        func cancel() {
            let toCancel = lock.withLock {
                isCancelledFlag = true
                return exchange(&subscriptionHandle, with: nil)
            }
            Self.cancelOnMainQueue(toCancel)
        }

        private static func cancelOnMainQueue(_ handle: AnyCancellable?) {
            guard let handle else {
                return
            }
            ImmediateIfOnMainQueueScheduler.shared.schedule {
                handle.cancel()
            }
        }

        var isCancelled: Bool {
            lock.withLock { isCancelledFlag }
        }
    }
}
