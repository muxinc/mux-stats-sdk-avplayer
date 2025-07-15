public import AVFoundation
import Combine
public import MuxCore

@objc(MUXSDKLogToBandwidthMetricCalculator)
public protocol LogToBandwidthMetricCalculator: AnyObject {
    func calculateBandwidthMetricFromAccessLog(_ log: AVPlayerItemAccessLog)
    func calculateBandwidthMetricFromErrorLog(_ log: AVPlayerItemErrorLog)
}

@available(iOS 13, tvOS 13, *)
@objc(MUXSDKPlayerMonitor)
public class PlayerMonitor: NSObject, ObservableObject {
    @objc public weak var calculator: LogToBandwidthMetricCalculator?
    
    var allEvents: some Publisher<MUXSDKBaseEvent, Never> {
        allEventsSubject
    }

    private let allEventsSubject = PassthroughSubject<MUXSDKBaseEvent, Never>()

    private var cancellables = [AnyCancellable]()
    
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
            .map { $0?.renditionInfoAndChangeEvents().eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher() }
            .switchToLatest()
            .sink(receiveValue: allEventsSubject.send)
            .store(in: &cancellables)
        
        if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
            player.publisher(for: \.currentItem, options: [.initial])
                .removeDuplicates()
                .compactMap { $0 }
                .flatMap {
                    let metricsPub = $0
                       .bandwidthMetricDataEventsUsingAVMetrics()
                       .eraseToAnyPublisher()
                       
                    $0.bandwidthMetricDataEventsUsingAccessLog()
                        .delay(for: .seconds(1), scheduler: ImmediateIfOnMainQueueScheduler.shared)
                        .prefix(untilOutputFrom: metricsPub)
                        .receive(on: ImmediateIfOnMainQueueScheduler.shared)
                        .sink(receiveValue: { self.calculator?.calculateBandwidthMetricFromAccessLog($0) })
                        .store(in: &self.cancellables)
                    
                    $0.bandwidthMetricDataEventsUsingErrorLog()
                        .delay(for: .seconds(1), scheduler: ImmediateIfOnMainQueueScheduler.shared)
                        .prefix(untilOutputFrom: metricsPub)
                        .receive(on: ImmediateIfOnMainQueueScheduler.shared)
                        .sink(receiveValue: { self.calculator?.calculateBandwidthMetricFromErrorLog($0) })
                        .store(in: &self.cancellables)
                    
                    return metricsPub
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
    }
}
