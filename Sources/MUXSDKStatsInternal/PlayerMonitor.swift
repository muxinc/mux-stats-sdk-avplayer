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

    @objc public func cancel() {
        allEventsSubject.send(completion: .finished)
        cancellables.removeAll()
    }
}

@available(iOS 15, tvOS 15, *)
extension PlayerMonitor {
    convenience init(player: AVPlayer, shouldGetBandwidthMetrics: Bool) {
        self.init()

        player.publisher(for: \.currentItem, options: [.initial])
            .removeDuplicates()
            .map { item in
                guard let item = item else {
                    return Empty<MUXSDKBaseEvent, Never>().eraseToAnyPublisher()
                }
                let renditionInfoAndChangeEvents = item.renditionInfoAndChangeEvents()
                
                guard shouldGetBandwidthMetrics, #available(iOS 18.0, tvOS 15.0, *) else {
                    return renditionInfoAndChangeEvents.eraseToAnyPublisher()
                }
                    
                let bandwidthMetricDataEvents = item.bandwidthMetricDataEventsUsingAVMetrics()
                
                return Publishers.Merge(
                    renditionInfoAndChangeEvents,
                    bandwidthMetricDataEvents
                ).eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink(receiveValue: allEventsSubject.send)
            .store(in: &cancellables)
    }

    @objc public convenience init(player: AVPlayer, shouldGetBandwidthMetrics: Bool, onEvent: @Sendable @escaping @MainActor (MUXSDKBaseEvent) -> Void) {
        self.init(player: player, shouldGetBandwidthMetrics: shouldGetBandwidthMetrics)

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
