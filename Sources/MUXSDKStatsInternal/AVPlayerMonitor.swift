import AVFoundation
import Combine
import MuxCore

@available(iOS 15, tvOS 15, *)
@MainActor
@objc(MUXSDKAVPlayerMonitor) public class AVPlayerMonitor : NSObject {

    private var currentItemMonitor: AVPlayerItemMonitor?
    private var cancellables: [AnyCancellable] = []

    @objc public init(player: AVPlayer, onEvent: (@escaping @MainActor (MUXSDKBaseEvent) -> Void)) {

        super.init()

        var connectables = [any ConnectablePublisher]()
        defer {
            cancellables += connectables.map { AnyCancellable($0.connect()) }
        }

        let currentItemPublisher = player.publisher(for: \.currentItem, options: [.initial])
            .subscribe(on: ImmediateIfOnMainQueueScheduler())
            .receive(on: ImmediateIfOnMainQueueScheduler())
            .removeDuplicates()
            .share()
            .makeConnectable()
        connectables.append(currentItemPublisher)

        let timeControlStatusPublisher = player.publisher(for: \.timeControlStatus, options: [.initial])
            .subscribe(on: ImmediateIfOnMainQueueScheduler())
            .receive(on: ImmediateIfOnMainQueueScheduler())
            .removeDuplicates()
            .makeConnectable()
        connectables.append(timeControlStatusPublisher)

        let isExternalPlaybackActivePublisher = player.publisher(for: \.isExternalPlaybackActive, options: [.initial])
            .subscribe(on: ImmediateIfOnMainQueueScheduler())
            .receive(on: ImmediateIfOnMainQueueScheduler())
            .removeDuplicates()
            .makeConnectable()
        connectables.append(isExternalPlaybackActivePublisher)

        // Produce a continuous stream of events from successive items
        let currentItemEvents = currentItemPublisher
            .map { [unowned self] currentItem in
                guard let currentItem else {
                    currentItemMonitor = nil
                    return Empty<MUXSDKBaseEvent, Never>().eraseToAnyPublisher()
                }
                let monitor = AVPlayerItemMonitor(playerItem: currentItem)
                // AVPlayerItemMonitor.allEvents does not retain its parent:
                currentItemMonitor = monitor
                return monitor.allEvents.eraseToAnyPublisher()
            }
            .switchToLatest()

        let allEvents = currentItemEvents
            .receive(on: ImmediateIfOnMainQueueScheduler())
            .map { event in
                logger.debug("Event from current item monitor: \(event)")
                if let playbackEvent = event as? MUXSDKPlaybackEvent {
                    let playerData = MUXSDKPlayerData()

                    // Note: this matches the implementation in MUXSDKPlayerBinding.m:
                    // .waitingToPlayAtSpecifiedRate will count as paused
                    playerData.playerIsPaused = (player.timeControlStatus != .playing) as NSNumber

                    // Note: this matches the implementation in MUXSDKPlayerBinding.m:
                    // playerRemotePlayed only set when true
                    if player.isExternalPlaybackActive {
                        playerData.playerRemotePlayed = true as NSNumber
                    }
                    playbackEvent.playerData = playerData
                }
                return event
            }

        // Start producing events:
        allEvents
            .sink(receiveValue: { event in
                onEvent(event)
            })
            .store(in: &cancellables)
    }

    @objc public func cancel() {
        cancellables.removeAll()
    }
}
