import AudioToolbox
import AVFoundation
import Combine
@preconcurrency import MuxCore

@available(iOS 15, tvOS 15, *)
struct AudioTrackChangeEvents {

    struct AudioTrackInfo: Equatable, Hashable, Sendable {
        let name: String
        let language: String?
        let codec: String?
        let bitrate: Int?
        let channels: MUXSDKAudioTrackChannelLayout?

        init(
            name: String,
            language: String?,
            codec: String?,
            bitrate: Int?,
            channels: MUXSDKAudioTrackChannelLayout?
        ) {
            self.name = name
            self.language = language
            self.codec = codec
            self.bitrate = bitrate
            self.channels = channels
        }

        @MainActor
        init?(_ playerItem: AVPlayerItem) async {
            guard let mediaSelectionOption = await playerItem.currentMediaSelection.selectedMediaOptionInGroup(for: .audible) else {
                return nil
            }

            if let hlsName = await mediaSelectionOption.loadHLSNameAttributeValue() {
                name = hlsName
            } else if let title = await mediaSelectionOption.loadTitle() {
                name = title
            } else {
                // This will be in the user's locale, so it is lowest preference.
                name = mediaSelectionOption.displayName
            }

            language = mediaSelectionOption.extendedLanguageTag

            let assetTrackInfo: AssetTrackInfo?
            if let assetTrack = await Self.selectedAudioAssetTrack(on: playerItem, language: language) {
                assetTrackInfo = await AssetTrackInfo(assetTrack)
            } else {
                assetTrackInfo = nil
            }

            codec = assetTrackInfo?.codec
            bitrate = assetTrackInfo?.bitrate
            channels = assetTrackInfo?.channels
        }

        @MainActor
        private static func selectedAudioAssetTrack(on playerItem: AVPlayerItem, language: String?) async -> AVAssetTrack? {
            let enabledAudioTracks = playerItem.tracks.compactMap { (track: AVPlayerItemTrack) -> AVAssetTrack? in
                guard track.isEnabled,
                      let assetTrack = track.assetTrack,
                      assetTrack.mediaType == .audio else {
                    return nil
                }
                return assetTrack
            }

            switch enabledAudioTracks.count {
            case 0:
                return nil
            case 1:
                return enabledAudioTracks.first
            default:
                guard let language else {
                    return nil
                }

                var matchingTracks = [AVAssetTrack]()
                for assetTrack in enabledAudioTracks {
                    if assetTrack.extendedLanguageTag == language {
                        matchingTracks.append(assetTrack)
                    }
                }

                return matchingTracks.count == 1 ? matchingTracks.first : nil
            }
        }
    }

    struct AssetTrackInfo: Equatable, Hashable, Sendable {
        let codec: String?
        let bitrate: Int?
        let channels: MUXSDKAudioTrackChannelLayout?

        @MainActor
        init?(_ assetTrack: AVAssetTrack) async {
            let formatDescriptions: [CMFormatDescription]
            let estimatedDataRate: Float
            do {
                (formatDescriptions, estimatedDataRate) = try await assetTrack.load(
                    .formatDescriptions,
                    .estimatedDataRate)
            } catch {
                logger.debug("Failed to load audio track metadata on \(assetTrack): \(error)")
                return nil
            }

            let audioFormatDescriptions = formatDescriptions.filter { $0.mediaType == .audio }
            codec = Self.uniqueValue(audioFormatDescriptions.compactMap(Self.codecString(for:)))

            if estimatedDataRate > 0 {
                bitrate = Int(estimatedDataRate.rounded())
            } else {
                bitrate = nil
            }

            channels = Self.uniqueValue(audioFormatDescriptions.compactMap(Self.channelLayout(for:)))
        }

        static func codecString(for formatDescription: CMFormatDescription) -> String? {
            guard formatDescription.mediaType == .audio else {
                return nil
            }

            return codecString(for: formatDescription.mediaSubType.rawValue)
        }

        static func codecString(for formatID: AudioFormatID) -> String? {
            // Explicit mappings only for common streaming-video audio codecs.
            // Return nil for anything else rather than guessing.
            switch formatID {
            case kAudioFormatAC3:
                return "ac-3"
            case kAudioFormatEnhancedAC3:
                return "ec-3"
            case kAudioFormatMPEG4AAC:
                return "mp4a.40.2"
            case kAudioFormatMPEG4AAC_HE:
                return "mp4a.40.5"
            case kAudioFormatMPEG4AAC_HE_V2:
                return "mp4a.40.29"
            case kAudioFormatMPEGD_USAC:
                return "mp4a.40.42"
            case kAudioFormatOpus:
                return "opus"
            default:
                return nil
            }
        }

        static func channelLayout(for formatDescription: CMFormatDescription) -> MUXSDKAudioTrackChannelLayout? {
            guard formatDescription.mediaType == .audio else {
                return nil
            }

            let audioFormatDescription = formatDescription as CMAudioFormatDescription

            var channelLayoutSize = 0
            if let channelLayout = CMAudioFormatDescriptionGetChannelLayout(
                audioFormatDescription,
                sizeOut: &channelLayoutSize
            ) {
                let layoutTag = channelLayout.pointee.mChannelLayoutTag
                if isAtmos(layoutTag: layoutTag) {
                    return .atmos
                }
            }

            guard let audioFormat = CMAudioFormatDescriptionGetRichestDecodableFormat(audioFormatDescription)
                ?? CMAudioFormatDescriptionGetMostCompatibleFormat(audioFormatDescription) else {
                return nil
            }

            return channelLayout(
                channelCount: Int(audioFormat.pointee.mASBD.mChannelsPerFrame),
                audioChannelLayoutTag: nil)
        }

        static func channelLayout(
            channelCount: Int,
            audioChannelLayoutTag: AudioChannelLayoutTag?
        ) -> MUXSDKAudioTrackChannelLayout? {
            if let audioChannelLayoutTag, isAtmos(layoutTag: audioChannelLayoutTag) {
                return .atmos
            }

            switch channelCount {
            case 1:
                return .mono
            case 2:
                return .stereo
            case 6:
                return .fivePointOne
            case 8:
                return .sevenPointOne
            case let count where count > 0:
                return .init("\(count)")
            default:
                return nil
            }
        }

        private static func isAtmos(layoutTag: AudioChannelLayoutTag) -> Bool {
            switch layoutTag {
            case kAudioChannelLayoutTag_Atmos_5_1_2,
                 kAudioChannelLayoutTag_Atmos_5_1_4,
                 kAudioChannelLayoutTag_Atmos_7_1_2,
                 kAudioChannelLayoutTag_Atmos_7_1_4,
                 kAudioChannelLayoutTag_Atmos_9_1_6:
                return true
            default:
                return false
            }
        }

        private static func uniqueValue<T: Hashable>(_ values: [T]) -> T? {
            let uniqueValues = Set(values)
            guard uniqueValues.count == 1 else {
                return nil
            }
            return uniqueValues.first
        }
    }

    let playerItem: AVPlayerItem
    let minimumIntervalBetweenEvents: TimeInterval

    init(playerItem: AVPlayerItem, minimumIntervalBetweenEvents: TimeInterval = 0.25) {
        self.playerItem = playerItem
        self.minimumIntervalBetweenEvents = minimumIntervalBetweenEvents
    }

    func allEvents() -> some Publisher<MUXSDKAudioTrackChangeEvent, Never> {
        playerItem.readyToPlayPublisher
            .catch { _ in
                // Ignore status failed error.
                return Empty<AVPlayerItem, Never>()
            }
            .flatMap { playerItem in
                let captureAudioTrackInfo = {
                    Future(priority: .userInitiated) { @MainActor in
                        async let timing = await playerItem.currentTiming()
                        let trackInfo = await AudioTrackInfo(playerItem)

                        return (
                            timing: await timing,
                            trackInfo: trackInfo
                        )
                    }
                }

                let audioTrackChanges = NotificationCenter.default
                    .publisher(
                        for: AVPlayerItem.mediaSelectionDidChangeNotification,
                        object: playerItem)
                    .flatMap { _ in captureAudioTrackInfo() }

                let audioTrackPublisher = Publishers.Concatenate(
                    prefix: captureAudioTrackInfo(),
                    suffix: audioTrackChanges)
                    // This can be a very noisy event stream, with intermediate states
                    // reported for fractions of a second.
                    .debounce(for: .seconds(minimumIntervalBetweenEvents), scheduler: DispatchQueue.global())
                    .removeDuplicates { a, b in
                        a.trackInfo == b.trackInfo
                    }

                return audioTrackPublisher
                    .map { trackInfoAndTiming in
                        MUXSDKAudioTrackChangeEvent(
                            timing: trackInfoAndTiming.timing,
                            trackInfo: trackInfoAndTiming.trackInfo)
                    }
            }
    }
}

@available(iOS 15, tvOS 15, *)
extension AVPlayerItem {
    nonisolated func audioTrackChangeEvents() -> some Publisher<MUXSDKAudioTrackChangeEvent, Never> {
        AudioTrackChangeEvents(playerItem: self).allEvents()
    }
}

@available(iOS 15, tvOS 15, *)
extension MUXSDKAudioTrackChangeEvent {
    convenience init(timing: PlaybackEventTiming,
                     trackInfo: AudioTrackChangeEvents.AudioTrackInfo?) {
        if let trackInfo {
            self.init(
                audioTrackEnabled: true as NSNumber,
                audioTrackName: trackInfo.name,
                audioTrackLanguage: trackInfo.language,
                audioTrackCodec: trackInfo.codec,
                audioTrackBitrate: trackInfo.bitrate.map(NSNumber.init(value:)),
                audioTrackChannels: trackInfo.channels)
        } else {
            self.init(
                audioTrackEnabled: false as NSNumber,
                audioTrackName: nil,
                audioTrackLanguage: nil,
                audioTrackCodec: nil,
                audioTrackBitrate: nil,
                audioTrackChannels: nil)
        }

        updateWithTiming(timing)
    }
}
