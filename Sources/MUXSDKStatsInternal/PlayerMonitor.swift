public import AVFoundation
import Combine
public import MuxCore


@available(iOS 13, tvOS 13, *)
@objc(MUXSDKPlayerMonitor)
public class PlayerMonitor: NSObject {

    var allEvents: some Publisher<MUXSDKBaseEvent, Never> {
        allEventsSubject
    }

    private let allEventsSubject = PassthroughSubject<MUXSDKBaseEvent, Never>()

    private var cancellables = [AnyCancellable]()

    @objc public private(set) var publishesRequestBandwidthEvents: Bool = false

    @objc public func cancel() {
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
            .map { $0?.renditionInfoAndChangeEvents().eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher() }
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

            publishesRequestBandwidthEvents = true
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
