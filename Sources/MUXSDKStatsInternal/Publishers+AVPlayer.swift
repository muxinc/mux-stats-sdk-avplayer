import AVFoundation
import Combine
import MuxCore

@available(iOS 16, tvOS 16, *)
@MainActor
@objc(MUXSDKAVPlayerMonitor) public class AVPlayerMonitor : NSObject {

    private var cancellables: [AnyCancellable] = []

    @objc public init(player: AVPlayer, onEvent: (@escaping @MainActor (MUXSDKBaseEvent) -> Void)) {

        super.init()

        var connectables = [any ConnectablePublisher]()
        defer {
            cancellables += connectables.map { AnyCancellable($0.connect()) }
        }

        let currentItemPublisher = player.publisher(for: \.currentItem, options: [.initial])
            .removeDuplicates()
            .share()
            .makeConnectable()
        connectables.append(currentItemPublisher)

        let timeControlStatusPublisher = player.publisher(for: \.timeControlStatus, options: [.initial])
            .removeDuplicates()
            .makeConnectable()
        connectables.append(timeControlStatusPublisher)

        let isExternalPlaybackActivePublisher = player.publisher(for: \.isExternalPlaybackActive, options: [.initial])
            .removeDuplicates()
            .makeConnectable()
        connectables.append(isExternalPlaybackActivePublisher)

        // Produce a continuous stream of events from successive items
        let currentItemEvents = currentItemPublisher
            .map { $0?.muxEventPublisher().eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher() }
            .switchToLatest()

        let allEvents = currentItemEvents
            .map { event in
                logger.debug("Event from current item monitor: \(event)")
                if let playbackEvent = event as? MUXSDKPlaybackEvent {
                    let playerData = MUXSDKPlayerData()

                    // Note: this matches the implementation in MUXSDKPlayerBinding.m:
                    // .waitingToPlayAtSpecifiedRate will count as paused
                    playerData.playerIsPaused = (player.timeControlStatus != .playing) as NSNumber

                    // Note: this matches the implementation in MUXSDKPlayerBinding:
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
            .receive(on: ImmediateIfOnMainQueueScheduler.shared)
            .sink(receiveValue: onEvent)
            .store(in: &cancellables)
    }

    @objc public func cancel() {
        cancellables.removeAll()
    }
}
