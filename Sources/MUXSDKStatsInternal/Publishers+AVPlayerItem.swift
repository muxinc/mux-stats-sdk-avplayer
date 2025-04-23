import AVFoundation
import Combine
import MuxCore
import os

extension AVPlayerItem {
    struct MuxEventPublisher {
        let playerItem: AVPlayerItem
    }

    func muxEventPublisher() -> MuxEventPublisher {
        MuxEventPublisher(playerItem: self)
    }
}

@available(iOS 16, tvOS 16, *)
extension AVPlayerItem.MuxEventPublisher: Publisher {
    typealias Output = MUXSDKBaseEvent
    typealias Failure = Never

    func receive(subscriber: some Subscriber<MUXSDKBaseEvent, Never>) {
        let s = AVPlayerItem.MuxEventSubscription(playerItem, subscriber)
        subscriber.receive(subscription: s)
    }
}

@available(iOS 16, tvOS 16, *)
extension AVPlayerItem {
    final class MuxEventSubscription {

        struct State {
            let playerItem: AVPlayerItem

            let subscriber: any Subscriber<MUXSDKBaseEvent, Never>

            var cancellables = Set<AnyCancellable>()

            private(set) var demand: Subscribers.Demand = .max(0)

            mutating func request(_ demand: Subscribers.Demand) {
                self.demand += demand
            }

            mutating func receive(_ input: MUXSDKBaseEvent) {
                guard demand > 0 else { return }
                demand += subscriber.receive(input)
            }
        }
        private var lockedState: OSAllocatedUnfairLock<State?>

        init(_ playerItem: AVPlayerItem, _ subscriber: some Subscriber<MUXSDKBaseEvent, Never>) {
            lockedState = .init(initialState: State(
                playerItem: playerItem,
                subscriber: subscriber))

            startObserving(playerItem: playerItem)
        }
    }
}

@available(iOS 16, tvOS 16, *)
extension AVPlayerItem.MuxEventSubscription: Cancellable {
    func cancel() {
        lockedState.withLock { $0 = nil }
    }
}

@available(iOS 16, tvOS 16, *)
extension AVPlayerItem.MuxEventSubscription: Subscription {
    func request(_ demand: Subscribers.Demand) {
        withMutableStateUnlessCancelled { $0.request(demand) }
    }
}


@available(iOS 16, tvOS 16, *)
extension AVPlayerItem.MuxEventSubscription {

    func withMutableStateUnlessCancelled<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R? where R : Sendable {
        try lockedState.withLock { state in
            guard state != nil else {
                return nil
            }
            return try body(&state!)
        }
    }

    func withMutableState<R>(_ body: @Sendable (inout State) -> R) throws(CancellationError) -> R where R : Sendable {
        let result: Result<R, CancellationError> = lockedState.withLock { state in
            guard state != nil else {
                return .failure(CancellationError())
            }
            return .success(body(&state!))
        }
        return try result.get()
    }

    func withMutableState<R>(_ body: @Sendable (inout State) throws -> R) throws -> R where R : Sendable {
        try lockedState.withLock { state in
            guard state != nil else {
                throw CancellationError()
            }
            return try body(&state!)
        }
    }

    @discardableResult
    func addTaskUnlessCancelled(priority: TaskPriority? = nil, operation: sending @escaping @isolated(any) () async -> Void) -> Bool {
        withMutableStateUnlessCancelled { [operation] state in
            state.cancellables.insert(AnyCancellable(Task(priority: priority, operation: operation).cancel))
            return true
        } ?? false
    }

    func send(_ event: MUXSDKBaseEvent) throws(CancellationError) {
        try withMutableState { $0.receive(event) }
    }
}

@available(iOS 16, tvOS 16, *)
extension AVPlayerItem.MuxEventSubscription {

    func startObserving(playerItem: AVPlayerItem) {
        var cancellables = [AnyCancellable]()

        let asset = playerItem.asset

        let durationFuture = asset.future(for: .duration)
        let variantsFuture = (asset as? AVURLAsset)?.future(for: .variants)

        let tracksPublisher = playerItem.publisher(for: \.tracks, options: [.initial])
            .removeDuplicates { tracksA, tracksB in
                tracksA.elementsEqual(tracksB) { trackA, trackB in
                    trackA.assetTrack?.trackID == trackB.assetTrack?.trackID
                }
            }
            .share()

        let statusPublisher = playerItem.publisher(for: \.status, options: [.initial])
            .removeDuplicates()
            .share()

        let validPresentationSizePublisher = playerItem.publisher(for: \.presentationSize, options: [.initial])
            .combineLatest(statusPublisher)
            .drop { (size, status) in
                // nonzero size is always valid - this will likely precede .readyToPlay
                size == .zero && status != .readyToPlay
            }
            .map { (size, status) in size }
            .removeDuplicates()
            .share()

        let videoAssetTrackPublisher = tracksPublisher
            // AVPlayerItemTrack.assetTrack is @MainActor isolated:
            .receive(on: ImmediateIfOnMainQueueScheduler.shared)
            // See docs on AVPlayerItem.tracks - this will be empty until loaded
            .drop(while: \.isEmpty)
            .map { tracks in
                tracks.lazy
                    .compactMap(\.assetTrack)
                    .first { $0.mediaType == .video }
            }
            .removeDuplicates { $0?.trackID == $1?.trackID }
            .share()

        let naturalSizePublisher = videoAssetTrackPublisher
            .map { assetTrack -> AnyPublisher<CGSize?, Never> in
                guard let assetTrack else {
                    return Just<CGSize?>(nil).eraseToAnyPublisher()
                }

                return assetTrack.future(for: .naturalSize)
                    .map(CGSize?.some)
                    .replaceError(with: nil)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .removeDuplicates()
            .share()

        let activeVariantPublisher = variantsFuture?
            .replaceError(with: [])
            .combineLatest(naturalSizePublisher)
            .map { variants, naturalSize in
                variants.first { $0.videoAttributes?.presentationSize == naturalSize }
            }
            .removeDuplicates()
            .share()


        let baseRenditionPublisher: AnyPublisher<(PlaybackEventTiming, AVAssetVariant?, CGSize), Never>
        if let activeVariantPublisher {
            baseRenditionPublisher = activeVariantPublisher
                .map { (PlaybackEventTiming(playerItem: playerItem), $0, playerItem.presentationSize) }
                .eraseToAnyPublisher()
        } else {
            // This backup will at least still fire when presentationSize changes:
            baseRenditionPublisher = validPresentationSizePublisher
                .map { (PlaybackEventTiming(playerItem: playerItem), nil, $0) }
                .eraseToAnyPublisher()
        }

        let initialDataEventPublisher = baseRenditionPublisher
            .first()
            .map { (timing, activeVariant, presentationSize) in
                let initialDataEvent = MUXSDKDataEvent()

                let videoData = MUXSDKVideoData()

                videoData.videoSourceUrl = (playerItem.asset as? AVURLAsset)?.url.absoluteString

                if let activeVariant {
                    videoData.updateWithAssetVariant(activeVariant)
                } else {
                    if presentationSize != .zero {
                        videoData.updateWithPresentationSize(presentationSize)
                    }
                }

                initialDataEvent.videoData = videoData

                return initialDataEvent
            }
            .combineLatest(durationFuture.map(Optional.some).replaceError(with: nil))
            .map { (event: MUXSDKDataEvent, assetDuration) in
                if let assetDuration {
                    event.videoData?.updateWithAssetDuration(assetDuration)
                }
                return event
            }

        initialDataEventPublisher
            .sink { [weak self] event in
                try? self?.send(event)
            }
            .store(in: &cancellables)

        var trackingRenditionChangesWithAVMetrics = false
        // AVMetrics does not seem to work on simulator
#if !targetEnvironment(simulator)
        if #available(iOS 18, tvOS 18, *) {
            let renditionChangeEvents = playerItem.metrics(forType: AVMetricPlayerItemVariantSwitchEvent.self)
                .filter(\.didSucceed)
                .map { metricEvent in
                    let renditionChangeEvent = MUXSDKRenditionChangeEvent()

                    let videoData = MUXSDKVideoData()
                    videoData.updateWithAssetVariant(metricEvent.toVariant)
                    renditionChangeEvent.videoData = videoData

                    let playerData = MUXSDKPlayerData()
                    playerData.playerPlayheadTime = metricEvent.mediaTime.seconds as NSNumber
                    // TODO: we could calculate programTime and playerLiveEdgeProgramTime
                    // use metricEvent.mediaTime and the offset between playerItem.currentTime() and playerItem.currentDate()
                    renditionChangeEvent.playerData = playerData

                    return renditionChangeEvent
                }

            addTaskUnlessCancelled { [weak self] in
                do {
                    for try await event in renditionChangeEvents {
                        guard let self else { return }
                        try self.send(event)
                    }
                } catch is CancellationError {
                } catch {
                    guard let self else { return }
                    logger.error("Error ")
                }
            }

            trackingRenditionChangesWithAVMetrics = true
        }
#endif

        if !trackingRenditionChangesWithAVMetrics {
            let renditionChangeEventPublisher = baseRenditionPublisher
                .dropFirst()
                .map { (timing, activeVariant, presentationSize) in
                    let renditionChangeEvent = MUXSDKRenditionChangeEvent()

                    let videoData = MUXSDKVideoData()

                    if let activeVariant {
                        videoData.updateWithAssetVariant(activeVariant)
                    } else {
                        if presentationSize != .zero {
                            videoData.videoSourceHeight = presentationSize.height as NSNumber
                            videoData.videoSourceWidth = presentationSize.width as NSNumber
                        }
                    }
                    renditionChangeEvent.videoData = videoData

                    let playerData = MUXSDKPlayerData()
                    playerData.playerPlayheadTime = timing.mediaTime.seconds as NSNumber
                    playerData.playerProgramTime = timing.programTime?.timeIntervalSince1970 as NSNumber?
                    playerData.playerLiveEdgeProgramTime = timing.liveEdgeProgramTime?.timeIntervalSince1970 as NSNumber?
                    renditionChangeEvent.playerData = playerData

                    return renditionChangeEvent
                }

            renditionChangeEventPublisher
                .sink { [weak self] renditionChangeEvent in
                    try? self?.send(renditionChangeEvent)
                }
                .store(in: &cancellables)
        }

        withMutableStateUnlessCancelled { [cancellables = consume cancellables] state in
            state.cancellables.formUnion(cancellables)
        }
    }
}
