public import AVFoundation
import Combine
import Dispatch
public import MuxCore


@available(iOS 13, tvOS 13, *)
@objc(MUXSDKPlayerMonitor)
public class PlayerMonitor: NSObject {

    var allEvents: some Publisher<MUXSDKBaseEvent, Never> {
        allEventsSubject
    }

    private let allEventsSubject = PassthroughSubject<MUXSDKBaseEvent, Never>()

    private var cancellables = [AnyCancellable]()

    @objc public func cancel() {
        // Events are delivered on the main queue (see `init(player:onEvent:)`'s
        // `.receive(on: ImmediateIfOnMainQueueScheduler.shared)`). Teardown must be
        // serialized with that delivery: callers (`-[MUXSDKPlayerBinding
        // detachAVPlayer]` -> `destroyPlayer`/`dealloc`) may invoke `cancel()` from
        // any thread, and tearing the subscription graph down off the main queue can
        // race an in-flight main-queue delivery and use-after-free the event being
        // dispatched (Pylon #26827). Hop to main so cancellation and delivery never
        // overlap. `self` is captured strongly so the graph stays alive until torn
        // down even if the caller drops its reference immediately after.
        if DispatchQueue.isMainQueue {
            performCancel()
        } else {
            // `PlayerMonitor` isn't Sendable, but `performCancel()` and everything it
            // touches run exclusively on the main queue (serialized with delivery), so
            // smuggling `self` across the hop is safe.
            nonisolated(unsafe) let unsafeSelf = self
            DispatchQueue.main.async {
                unsafeSelf.performCancel()
            }
        }
    }

    private func performCancel() {
        allEventsSubject.send(completion: .finished)
        cancellables.removeAll()
    }
}

@available(iOS 15, tvOS 15, *)
extension PlayerMonitor {
    convenience init(player: AVPlayer) {
        self.init()

        let currentItemPublisher = player.publisher(for: \.currentItem, options: [.initial])
            .removeDuplicates()

        currentItemPublisher
            .map { $0?.renditionChangeEvents().eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher() }
            .switchToLatest()
            .sink(receiveValue: allEventsSubject.send)
            .store(in: &cancellables)

        currentItemPublisher
            .map { $0?.textTrackChangeEvents().eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher() }
            .switchToLatest()
            .sink(receiveValue: allEventsSubject.send)
            .store(in: &cancellables)

        currentItemPublisher
            .map { $0?.audioTrackChangeEvents().eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher() }
            .switchToLatest()
            .sink(receiveValue: allEventsSubject.send)
            .store(in: &cancellables)

#if !targetEnvironment(simulator)
        if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
            currentItemPublisher
                .map { $0?.requestBandwidthEvents().eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher() }
                .switchToLatest()
                .sink(receiveValue: allEventsSubject.send)
                .store(in: &cancellables)
        }
#endif
    }

    @objc public convenience init(player: AVPlayer, onEvent: @Sendable @escaping @MainActor (MUXSDKBaseEvent) -> Void) {
        self.init(player: player)

        allEvents
            .receive(on: ImmediateIfOnMainQueueScheduler.shared)
            .sink(receiveValue: { event in
                // work around Sendable requirement on assumeIsolated
                nonisolated(unsafe) let event = event
                MainActor.assumeIsolated {
                    onEvent(event)
                }
            })
            .store(in: &cancellables)
    }
}
