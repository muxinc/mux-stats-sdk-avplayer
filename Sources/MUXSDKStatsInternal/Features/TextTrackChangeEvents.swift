import AVFoundation
import Combine
@preconcurrency import MuxCore

extension MUXSDKTextTrackType {
    init?(_ mediaType: AVMediaType) {
        switch mediaType {
        case .subtitle:
            self = .subtitles
        case .closedCaption:
            self = .closedCaptions
        default:
            return nil
        }
    }

    @available(iOS 13, tvOS 13, *)
    var formatDescriptionMediaType: CMFormatDescription.MediaType? {
        switch self {
        case .closedCaptions:
            .closedCaption
        case .subtitles:
            .subtitle
        default:
            nil
        }
    }
}

@available(iOS 13, tvOS 13, *)
extension MUXSDKTextTrackFormat {
    init?(_ mediaSubType: CMFormatDescription.MediaSubType) {
        switch mediaSubType {
        case .cea608:
            self = .cea608
        case .cea708:
            self = .cea708
        case .webVTT:
            self = .webVTT
        default:
            return nil
        }
    }
}

@available(iOS 15, tvOS 15, *)
struct TextTrackChangeEvents {

    /// Represents the selected text track option (see AVMediaSelectionOption) but not necessarily the current presentation state
    struct MediaSelectionOptionInfo: Equatable, Hashable, Sendable {
        let name: String
        let trackType: MUXSDKTextTrackType
        let mediaType: AVMediaType
        let language: String?

        @MainActor
        init?(_ mediaSelection: AVMediaSelection) async {
            guard let mediaSelectionOption = await mediaSelection.selectedMediaOptionInGroup(for: .legible),
                  let trackType = MUXSDKTextTrackType(mediaSelectionOption.mediaType) else {
                return nil
            }

            self.trackType = trackType
            self.mediaType = mediaSelectionOption.mediaType

            if let hlsName = await mediaSelectionOption.loadHLSNameAttributeValue() {
                name = hlsName
            } else if let title = await mediaSelectionOption.loadTitle() {
                name = title
            } else {
                // This will be in the user's locale, so it is lowest preference
                name = mediaSelectionOption.displayName
            }

            language = mediaSelectionOption.extendedLanguageTag
        }
    }

    /// Represents the current presentation state (see AVAssetTrack), unfortunately containing minimal information about the source option
    struct AssetTrackInfo: Equatable, Hashable, Sendable {
        let trackType: MUXSDKTextTrackType
        let trackFormat: MUXSDKTextTrackFormat

        @MainActor
        init?(_ assetTrack: AVAssetTrack) async {
            guard let trackType = MUXSDKTextTrackType(assetTrack.mediaType),
                  let formatDescriptionMediaType = trackType.formatDescriptionMediaType else {
                    return nil
                }

            let formatDescriptions: [CMFormatDescription]
            do {
                formatDescriptions = try await assetTrack.load(.formatDescriptions)
            } catch {
                logger.debug("Failed to load format descriptions on \(assetTrack): \(error)")
                return nil
            }

            guard let trackFormat = formatDescriptions
                .filter({ $0.mediaType == formatDescriptionMediaType })
                .compactMap({ MUXSDKTextTrackFormat($0.mediaSubType) })
                .first else {
                return nil
            }

            self.trackType = trackType
            self.trackFormat = trackFormat
        }
    }

    let playerItem: AVPlayerItem
    let minimumIntervalBetweenEvents: TimeInterval

    init(playerItem: AVPlayerItem, minimumIntervalBetweenEvents: TimeInterval = 0.25) {
        self.playerItem = playerItem
        self.minimumIntervalBetweenEvents = minimumIntervalBetweenEvents
    }

    func allEvents() -> some Publisher<MUXSDKTextTrackChangeEvent, Never> {
        playerItem.readyToPlayPublisher
            .catch { _ in
                // Ignore status failed error
                return Empty<AVPlayerItem, Never>()
            }
            .flatMap { playerItem in

                let captureMediaSelectionOption = {
                    Future(priority: .userInitiated) { @MainActor in
                        async let timing = await playerItem.currentTiming()

                        let selectionInfo = await MediaSelectionOptionInfo(playerItem.currentMediaSelection)

                        return (
                            timing: await timing,
                            selectionInfo: selectionInfo
                        )
                    }
                }

                let mediaSelectionOptionChanges = NotificationCenter.default
                    .publisher(
                        for: AVPlayerItem.mediaSelectionDidChangeNotification,
                        object: playerItem)
                    .flatMap { _ in captureMediaSelectionOption() }

                let mediaSelectionOptionPublisher = Publishers.Concatenate(
                    prefix: captureMediaSelectionOption(),
                    suffix: mediaSelectionOptionChanges)
                    .removeDuplicates { a, b in
                        a.selectionInfo == b.selectionInfo
                    }

                return mediaSelectionOptionPublisher
                    .map { @MainActor selectionOptionAndTiming in
                        let timing = selectionOptionAndTiming.timing

                        guard let selectionOption = selectionOptionAndTiming.selectionInfo else {
                            // No text track
                            return MUXSDKTextTrackChangeEvent(
                                timing: timing,
                                selectionOption: nil)
                        }

                        // Attempt to match presented tracks
                        for track in playerItem.tracks {
                            if let assetTrack = track.assetTrack,
                               assetTrack.mediaType == selectionOption.mediaType,
                               let trackInfo = await AssetTrackInfo(assetTrack),
                               trackInfo.trackType == selectionOption.trackType {
                                return MUXSDKTextTrackChangeEvent(
                                    timing: timing,
                                    selectionOption: selectionOption,
                                    assetTrack: trackInfo)
                            }
                        }

                        // Report all available info without matched track
                        return MUXSDKTextTrackChangeEvent(
                            timing: timing,
                            selectionOption: selectionOption,
                            assetTrack: nil)
                    }
                    .debounce(for: .seconds(minimumIntervalBetweenEvents), scheduler: DispatchQueue.global())
            }
    }
}

@available(iOS 15, tvOS 15, *)
extension AVPlayerItem {
    nonisolated func textTrackChangeEvents() -> some Publisher<MUXSDKTextTrackChangeEvent, Never> {
        TextTrackChangeEvents(playerItem: self).allEvents()
    }
}

@available(iOS 15, tvOS 15, *)
extension MUXSDKTextTrackChangeEvent {
    convenience init(timing: PlaybackEventTiming,
                     selectionOption: TextTrackChangeEvents.MediaSelectionOptionInfo?) {
        if let selectionOption {
            self.init(
                textTrackEnabled: true as NSNumber,
                textTrackType: selectionOption.trackType,
                textTrackFormat: nil,
                textTrackName: selectionOption.name,
                textTrackLanguage: selectionOption.language)
        } else {
            self.init(
                textTrackEnabled: false as NSNumber,
                textTrackType: nil,
                textTrackFormat: nil,
                textTrackName: nil,
                textTrackLanguage: nil)
        }

        updateWithTiming(timing)
    }

    convenience init(timing: PlaybackEventTiming,
                     selectionOption: TextTrackChangeEvents.MediaSelectionOptionInfo,
                     assetTrack: TextTrackChangeEvents.AssetTrackInfo?) {
        self.init(
            textTrackEnabled: true as NSNumber,
            textTrackType: selectionOption.trackType,
            textTrackFormat: assetTrack?.trackFormat,
            textTrackName: selectionOption.name,
            textTrackLanguage: selectionOption.language)

        updateWithTiming(timing)
    }
}
