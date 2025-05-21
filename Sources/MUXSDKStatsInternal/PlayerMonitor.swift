import AVFoundation
import Combine
import MuxCore


@available(iOS 13, tvOS 13, *)
@objc(MUXSDKPlayerMonitor)
public class PlayerMonitor: NSObject, ObservableObject {
    @Published
    private(set) var playerIsPaused: Bool = false

    @Published
    private(set) var playerRemotePlayed: Bool = false

    func playerDataPublisher() -> some Publisher<MUXSDKPlayerData, Never> {
        Publishers.CombineLatest($playerIsPaused, $playerRemotePlayed)
            .map { playerIsPaused, playerRemotePlayed in
                let playerData = MUXSDKPlayerData()
                playerData.playerIsPaused = playerIsPaused as NSNumber
                playerData.playerRemotePlayed = playerRemotePlayed as NSNumber
                return playerData
            }
    }

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
    @objc public convenience init(player: AVPlayer, onEvent: (@escaping @MainActor (MUXSDKBaseEvent) -> Void)) {
        self.init()

        player.publisher(for: \.timeControlStatus, options: [.initial])
            .map { $0 != .playing }
            .removeDuplicates()
            .assign(to: &$playerIsPaused)

#if os(iOS) || os(tvOS) || os(macOS)
        player.publisher(for: \.isExternalPlaybackActive, options: [.initial])
            .removeDuplicates()
            .assign(to: &$playerRemotePlayed)
#endif

        player.publisher(for: \.currentItem, options: [.initial])
            .removeDuplicates()
            .compactMap { $0?.renditionInfoAndChangeEvents(playerData: self.playerDataPublisher()) }
            .switchToLatest()
            .sink(receiveValue: allEventsSubject.send)
            .store(in: &cancellables)

        allEvents
            .receive(on: ImmediateIfOnMainQueueScheduler.shared)
            .sink(receiveValue: { event in
                MainActor.assumeIsolated {
                    onEvent(event)
                }
            })
            .store(in: &cancellables)
    }
}
