public import AVFoundation
import Combine
public import MuxCore


@available(iOS 13, tvOS 13, *)
@objc(MUXSDKPlayerMonitor)
public class PlayerMonitor: NSObject, ObservableObject {
    @objc public var isCalculatingBandwidthMetrics: Bool // Do I need any concurrency check to access this from objc?
    
    var allEvents: some Publisher<MUXSDKBaseEvent, Never> {
        allEventsSubject
    }

    private let allEventsSubject = PassthroughSubject<MUXSDKBaseEvent, Never>()

    private var cancellables = [AnyCancellable]()

    override init() {
        self.isCalculatingBandwidthMetrics = false
    }
}

@available(iOS 13, tvOS 13, *)
extension PlayerMonitor: Cancellable {
    @objc public func cancel() {
        allEventsSubject.send(completion: .finished)
        cancellables.removeAll()
    }
}

@available(iOS 15, tvOS 15, *)
extension PlayerMonitor {
    convenience init(player: AVPlayer) {
        self.init()

        player.publisher(for: \.currentItem, options: [.initial])
            .removeDuplicates()
            .map { item in
                guard let item = item else {
                    return Empty<MUXSDKBaseEvent, Never>().eraseToAnyPublisher()
                }
                let renditionInfoAndChangeEvents = item.renditionInfoAndChangeEvents()
                
                return renditionInfoAndChangeEvents.eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink(receiveValue: allEventsSubject.send)
            .store(in: &cancellables)
        
        if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
            player.publisher(for: \.currentItem, options: [.initial])
                .removeDuplicates()
                .map { item in
                    self.isCalculatingBandwidthMetrics = false
                    guard let item = item else {
                        return Empty<MUXSDKBaseEvent, Never>().eraseToAnyPublisher()
                    }
                    
                    let bandwidthMetricDataEvents = item.bandwidthMetricDataEventsUsingAVMetrics()
                    return bandwidthMetricDataEvents.eraseToAnyPublisher()
                }
                .switchToLatest()
                .sink(receiveValue: allEventsSubject.send)
                .store(in: &cancellables)
        }
    }

    @objc public convenience init(
        player: AVPlayer,
        onEvent: @Sendable @escaping @MainActor (MUXSDKBaseEvent) -> Void
    ) {
        self.init(player: player)

        allEvents
            .receive(on: ImmediateIfOnMainQueueScheduler.shared)
            .sink(receiveValue: { event in
                if !self.isCalculatingBandwidthMetrics,
                    let _ = event as? MUXSDKRequestBandwidthEvent
                {
                    self.isCalculatingBandwidthMetrics = true
                }

                // work around Sendable requirement on assumeIsolated
                nonisolated(unsafe) let event = event
                MainActor.assumeIsolated {
                    onEvent(event)
                }
            })
            .store(in: &cancellables)
    }
}
