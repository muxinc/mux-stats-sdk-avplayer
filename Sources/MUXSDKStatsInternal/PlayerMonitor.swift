public import AVFoundation
import Combine
public import MuxCore

@objc(MUXSDKCalculatingBandwidthMetricsObserver)
public protocol IsCalculatingBandwidthMetricsObserver: AnyObject {
    func onCalculatingBandwidthMetricsChange(_ change: Bool)
}

@available(iOS 13, tvOS 13, *)
@objc(MUXSDKPlayerMonitor)
public class PlayerMonitor: NSObject, ObservableObject {
    @objc public weak var observer: IsCalculatingBandwidthMetricsObserver?
    
    var allEvents: some Publisher<MUXSDKBaseEvent, Never> {
        allEventsSubject
    }

    private let allEventsSubject = PassthroughSubject<MUXSDKBaseEvent, Never>()

    private var cancellables = [AnyCancellable]()
    
    private let isCalculatingBandwidthMetricsSubject = CurrentValueSubject<Bool, Never>(false)
    
    @objc public func isCalculatingBandwidthMetrics() -> Bool {
        return isCalculatingBandwidthMetricsSubject.value;
    }
    
    override init() {
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
                .compactMap { $0 }
                .handleEvents(receiveOutput: { _ in
                    self.isCalculatingBandwidthMetricsSubject.send(false)
                })
                .flatMap { item  in
                    let metricsPub = item
                        .bandwidthMetricDataEventsUsingAVMetrics()
                        .share()
                    
                    // We have to sink this so we don't send duplicated events.
                    metricsPub
                        .prefix(1)
                        .sink {_ in self.isCalculatingBandwidthMetricsSubject.send(true)}
                        .store(in: &self.cancellables)
                    
                    return metricsPub.eraseToAnyPublisher()
                }
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
                // work around Sendable requirement on assumeIsolated
                nonisolated(unsafe) let event = event
                MainActor.assumeIsolated {
                    onEvent(event)
                }
            })
            .store(in: &cancellables)
        
        isCalculatingBandwidthMetricsSubject
            .receive(on: ImmediateIfOnMainQueueScheduler.shared)
            .removeDuplicates()
            .sink { isCalculating in
                guard let observer = self.observer else { return }
                observer.onCalculatingBandwidthMetricsChange(isCalculating)
            }
            .store(in: &cancellables)
    }
}
