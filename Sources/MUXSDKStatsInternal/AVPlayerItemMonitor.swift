import AVFoundation
import Combine
import MuxCore

@available(iOS 15, tvOS 15, *)
@MainActor
class AVPlayerItemMonitor {

    struct State: Sendable {
        let assetURL: URL?
        var status: AVPlayerItem.Status
        var duration: CMTime?
        var variants: [AVAssetVariant]?
        var naturalSize: CGSize?
        var activeVariant: AVAssetVariant? {
            guard let naturalSize, let variants else {
                return nil
            }
            return variants.first { variant in
                variant.videoAttributes?.presentationSize == naturalSize
            }
        }
    }
    var state: State

    private func send(event: some MUXSDKBaseEvent) {
        allEventsSubject.send(event)
    }

    // TODO: The subscription created from this publisher should start the observing
    // (Only if sticking with Combine norms as a basis for observation)
    var allEvents: some Publisher<MUXSDKBaseEvent, Never> {
        allEventsSubject
    }

    private let allEventsSubject = PassthroughSubject<MUXSDKBaseEvent, Never>()
    private var cancellables = [AnyCancellable]()

    private let shouldTriggerRenditionChangeOnTrackChange: Bool

    init(playerItem: AVPlayerItem) {
        let asset = playerItem.asset
        let urlAsset = asset as? AVURLAsset
        state = State(
            assetURL: urlAsset?.url,
            status: playerItem.status)

        if #available(iOS 18, tvOS 18, *) {
#if targetEnvironment(simulator)
            // AVMetrics does not seem to work on simulator
            shouldTriggerRenditionChangeOnTrackChange = true
#else
            shouldTriggerRenditionChangeOnTrackChange = false
            Task {
                await trackRenditionChangesUsingAVMetrics(playerItem: playerItem)
            }
#endif
        } else {
            shouldTriggerRenditionChangeOnTrackChange = true
        }

        if let urlAsset {
            loadAssetData(urlAsset)
        }

        var connectables = [any ConnectablePublisher]()
        defer {
            cancellables += connectables.map { AnyCancellable($0.connect()) }
        }

        let tracksPublisher = playerItem.publisher(for: \.tracks, options: [.initial])
            .subscribe(on: DispatchQueue.main)
            .receive(on: ImmediateIfOnMainQueueScheduler())
            .removeDuplicates(by: { tracksA, tracksB in
                tracksA.elementsEqual(tracksB) { trackA, trackB in
                    trackA.assetTrack?.trackID == trackB.assetTrack?.trackID
                }
            })
            .share()
            .makeConnectable()
        connectables.append(tracksPublisher)

        let videoAssetTrackPublisher = tracksPublisher.map { tracks in
            tracks.lazy
                .compactMap(\.assetTrack)
                .first { $0.mediaType == .video }
        }
            .removeDuplicates { trackA, trackB in
                trackA?.trackID == trackB?.trackID
            }

        let naturalSizePublisher = videoAssetTrackPublisher
            .map { assetTrack -> AnyPublisher<CGSize?, Never> in
                guard let assetTrack else {
                    return Just<CGSize?>(nil).eraseToAnyPublisher()
                }

                return assetTrack.future(for: .naturalSize)
                    .map(CGSize?.some)
                    .replaceError(with: nil)
                    .receive(on: ImmediateIfOnMainQueueScheduler())
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .removeDuplicates()

        naturalSizePublisher
            .sink { [unowned self] naturalSize in
                if let naturalSize {
                    logger.debug("AVPlayerItem video track size changed to \(naturalSize.width, format: .fixed(precision: 0))x\(naturalSize.height, format: .fixed(precision: 0))")
                }
                let previousVariant = state.activeVariant
                state.naturalSize = naturalSize
                let newVariant = state.activeVariant

                if shouldTriggerRenditionChangeOnTrackChange {
                    // Note: not the permanent location for this logic:
                    if let previousVariant,
                       let newVariant,
                       previousVariant != newVariant,
                       let naturalSize, naturalSize != .zero {
                        let renditionChangeEvent = MUXSDKRenditionChangeEvent()

                        let videoData = MUXSDKVideoData()
                        videoData.videoSourceWidth = naturalSize.width as NSNumber
                        videoData.videoSourceHeight = naturalSize.height as NSNumber
                        videoData.updateWithAssetVariant(newVariant)
                        renditionChangeEvent.videoData = videoData

                        // TODO: this timing information should come through the event chain, not be accessed here:
                        let playerData = MUXSDKPlayerData()
                        playerData.playerPlayheadTime = playerItem.currentTime().seconds as NSNumber
                        // TODO: we can calculate playerLiveEdgeProgramTime with this:
                        _ = playerItem.loadedTimeRanges
                        renditionChangeEvent.playerData = playerData

                        send(event: renditionChangeEvent)
                    }
                }
        }
        .store(in: &cancellables)
    }

    nonisolated private func loadAssetData(_ asset: AVURLAsset) {
        Task { [weak self] in
            do {
                let (duration,
                     variants)
                = try await asset.load(
                    .duration,
                    .variants)

                logger.debug("AVPlayerItem.asset loaded duration=\(duration.loggable) variants=\(variants)")

                Task { @MainActor in
                    guard let self else { return }
                    self.state.duration = duration
                    self.state.variants = variants

                    let initialDataEvent = MUXSDKDataEvent()

                    let videoData = MUXSDKVideoData()

                    videoData.videoSourceUrl = self.state.assetURL?.absoluteString

                    videoData.updateWithAssetDuration(duration)

                    if let naturalSize = self.state.naturalSize, naturalSize != .zero {
                        videoData.videoSourceWidth = naturalSize.width as NSNumber
                        videoData.videoSourceHeight = naturalSize.height as NSNumber
                    }

                    if let activeVariant = self.state.activeVariant {
                        videoData.updateWithAssetVariant(activeVariant)
                    }

                    initialDataEvent.videoData = videoData

                    self.send(event: initialDataEvent)
                }
            } catch {
                logger.error("Error loading asset data: \(error)")
            }
        }
    }

    @available(iOS 18, tvOS 18, *)
    nonisolated private func trackRenditionChangesUsingAVMetrics(playerItem: AVPlayerItem) {
        let successfulVariantSwitchEvents = playerItem.metrics(forType: AVMetricPlayerItemVariantSwitchEvent.self)
            .filter { $0.didSucceed }

        Task { [weak self] in
            do {
                for try await metricEvent in successfulVariantSwitchEvents {
                    guard let self else { return }
                    try Task.checkCancellation()

                    let renditionChangeEvent = MUXSDKRenditionChangeEvent()

                    let videoData = MUXSDKVideoData()
                    videoData.updateWithAssetVariant(metricEvent.toVariant)
                    renditionChangeEvent.videoData = videoData

                    let playerData = MUXSDKPlayerData()
                    playerData.playerPlayheadTime = metricEvent.mediaTime.seconds as NSNumber
                    // TODO: we can calculate playerLiveEdgeProgramTime with this:
                    _ = metricEvent.loadedTimeRanges
                    renditionChangeEvent.playerData = playerData

                    Task { @MainActor [weak self] in
                        self?.send(event: renditionChangeEvent)
                    }
                }
            } catch is CancellationError {
            } catch {
                guard let _ = self else { return }
                logger.error("Error in AVMetrics rendition change tracking: \(error)")
            }
        }
    }
}
