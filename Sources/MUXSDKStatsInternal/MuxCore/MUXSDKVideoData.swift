import AVFoundation
import MuxCore

// Only these values cross the async rendition-loading pipeline.
struct RenditionInfo: Sendable {
    // Preserve the original Float (track) and Double (variant) NSNumber representations.
    var trackFrameRate: Float?
    var variantFrameRate: Double?
    var presentationSize: CGSize?
    var advertisedBitrate: Double?

    @available(iOS 15, tvOS 15, *)
    mutating func updateWithAssetVariant(_ assetVariant: AVAssetVariant) {
        if let peakBitRate = assetVariant.peakBitRate {
            advertisedBitrate = peakBitRate
        }

        guard let videoAttributes = assetVariant.videoAttributes else { return }
        if let nominalFrameRate = videoAttributes.nominalFrameRate {
            variantFrameRate = nominalFrameRate
        }

        if videoAttributes.presentationSize != .zero {
            presentationSize = videoAttributes.presentationSize
        }
    }

    @available(iOS 15, tvOS 15, *)
    static func load(track: AVAssetTrack, on playerItem: AVPlayerItem) async -> Self {
        var renditionInfo = Self()
        // Obtain recent bitrate stats immediately in case another variant switch happens
        async let bitratesFromAccessLog = withTimeout(seconds: 5) {
            Array(try await playerItem.indicatedBitratesInAccessLog.suffix(3))
        }
        // Start loading this early:
        async let assetVariantsOrNil = {
            // AVURLAsset subclass is Sendable
            let urlAsset = await MainActor.run {
                playerItem.asset as? AVURLAsset
            }
            return try await urlAsset?.load(.variants)
        }()

        let nominalFrameRate: Float?
        let presentationSize: CGSize?
        let videoFormatDescriptions: [CMFormatDescription]
        let videoRangeIsHDR: Bool?

        do {
            let (
                naturalSizeOrZero,
                nominalFrameRateOrZero,
                formatDescriptions,
                mediaCharacteristics
            ) = try await track.load(
                .naturalSize,
                .nominalFrameRate,
                .formatDescriptions,
                .mediaCharacteristics
            )

            presentationSize = naturalSizeOrZero == .zero ? nil : naturalSizeOrZero
            nominalFrameRate = nominalFrameRateOrZero == .zero ? nil : nominalFrameRateOrZero
            videoFormatDescriptions = formatDescriptions.filter { $0.mediaType == .video }
            videoRangeIsHDR = mediaCharacteristics.contains(.containsHDRVideo) ? true : nil
        } catch {
            if !(error is CancellationError) {
                logger.error("Track \(track.trackID): failed to load basic video attributes: \(error)")
            }
            return renditionInfo
        }

        let videoCodecs = Set<CMVideoCodecType>(
            videoFormatDescriptions
                .map(\.mediaSubType.rawValue)
                .filter { $0 != .zero }
        )

        // Set these right away so they're available even if variants are unavailable or matching fails:
        renditionInfo.trackFrameRate = nominalFrameRate
        renditionInfo.presentationSize = presentationSize

        // Matching below based on the following assumptions:
        //
        //  HLS Attribute     | AVAssetVariant key path
        //  ------------------+---------------------------------
        //  RESOLUTION        | videoAttributes.presentationSize
        //  FRAME-RATE        | videoAttributes.nominalFrameRate
        //  CODECS            | (audio/video)Attributes.codecTypes
        //  VIDEO-RANGE       | videoAttributes.videoRange
        //  BANDWIDTH         | peakBitRate
        //  AVERAGE-BANDWIDTH | averageBitRate

        let assetVariants: [AVAssetVariant]
        do {
            // Bail out when no variants present (including non-HLS assets)
            guard let assetVariantsOrNil = try await assetVariantsOrNil, !assetVariantsOrNil.isEmpty else {
                return renditionInfo
            }
            assetVariants = assetVariantsOrNil
        } catch {
            if !(error is CancellationError) {
                logger.error("Track \(track.trackID): failed to load variants: \(error)")
            }
            return renditionInfo
        }

        let matchingVariants = assetVariants.filter { variant in
            guard let videoAttributes = variant.videoAttributes else {
                return false
            }

            if let presentationSize, videoAttributes.presentationSize != .zero {
                guard videoAttributes.presentationSize == presentationSize else {
                    return false
                }
            }

            if let nominalFrameRate, let variantNominalFrameRate = videoAttributes.nominalFrameRate {
                guard nominalFrameRate == Float(variantNominalFrameRate) else {
                    return false
                }
            }

            if !videoCodecs.isEmpty, !videoAttributes.codecTypes.isEmpty {
                guard !videoCodecs.isDisjoint(with: videoAttributes.codecTypes) else {
                    return false
                }
            }

            return true
        }

        switch matchingVariants.count {
        case 0:
            logger.debug("""
                Track \(track.trackID): No matching variants detected by basic video attributes
                    presentationSize=\(presentationSize.debugDescription)
                    nominalFrameRate=\(nominalFrameRate.debugDescription)
                    videoCodecs=\(videoCodecs.map(CMFormatDescription.MediaSubType.init(rawValue:)))
                    videoRangeIsHDR=\(videoRangeIsHDR.debugDescription)
                    variants=\(assetVariants)
                """)
            return renditionInfo
        case 1:
            renditionInfo.updateWithAssetVariant(matchingVariants.first!)
            return renditionInfo
        default:
            break
        }

        // Separate, last-ditch procedure here as this access log process can be less exact.
        logger.debug("Track \(track.trackID): Attempting to match variant by recent indicated bitrates in access log")

        let recentBitrates: [Double]

        do {
            recentBitrates = try await bitratesFromAccessLog
        } catch {
            if !(error is CancellationError) {
                logger.debug("Track \(track.trackID): failed to load bitrates from access log: \(error)")
            }
            return renditionInfo
        }

        // Effectively handles getting the initial bitrate for a stream, which is an increasingly common use case.
        // There will be one matching entry in the access log, and all further variant info will come from
        // `AVMetricPlayerItemVariantSwitchEvent.toVariant` on iOS 18+.
        if recentBitrates.count == 1 {
            renditionInfo.advertisedBitrate = recentBitrates.first!
        }

        for bitrate in recentBitrates.reversed() {
            let bitrateMatched = matchingVariants.filter { variant in
                variant.peakBitRate == bitrate
            }
            switch bitrateMatched.count {
            case 0:
                break
            case 1:
                renditionInfo.updateWithAssetVariant(bitrateMatched.first!)
                return renditionInfo
            default:
                renditionInfo.advertisedBitrate = recentBitrates.first!
                logger.debug("Track \(track.trackID): Multiple matching variants detected after filtering by bitrate=\(bitrate): \(bitrateMatched)")
                return renditionInfo
            }
        }

        logger.debug("""
            Track \(track.trackID): No matching variants detected:
                presentationSize=\(presentationSize.debugDescription)
                nominalFrameRate=\(nominalFrameRate.debugDescription)
                videoCodecs=\(videoCodecs.map(CMFormatDescription.MediaSubType.init(rawValue:)))
                videoRangeIsHDR=\(videoRangeIsHDR.debugDescription)
                recentBitrates=\(recentBitrates)
                variants=\(assetVariants)
            """)
        return renditionInfo
    }
}

extension MUXSDKVideoData {
    convenience init(renditionInfo: RenditionInfo) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.init()
        videoSourceAdvertisedFrameRate = (renditionInfo.variantFrameRate as NSNumber?)
            ?? (renditionInfo.trackFrameRate as NSNumber?)
        videoSourceAdvertisedBitrate = renditionInfo.advertisedBitrate as NSNumber?
        if let size = renditionInfo.presentationSize {
            videoSourceHeight = size.height as NSNumber
            videoSourceWidth = size.width as NSNumber
        }
    }
}
