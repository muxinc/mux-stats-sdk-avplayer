import AVFoundation
import MuxCore

extension MUXSDKVideoData {
    func updateWithPresentationSize(_ presentationSize: CGSize) {
        videoSourceHeight = presentationSize.height as NSNumber
        videoSourceWidth = presentationSize.width as NSNumber
    }

    func updateWithVideoCodecTypes(_ videoCodecs: [CMVideoCodecType]) {
        // TODO: videoSourceAdvertisedCodec (RFC 6381)
    }

    @available(iOS 15, tvOS 15, *)
    func updateWithAssetVariant(_ assetVariant: AVAssetVariant) {
        if let peakBitRate = assetVariant.peakBitRate {
            videoSourceAdvertisedBitrate = peakBitRate as NSNumber
        }

        assetVariant.videoAttributes.map(updateWithVideoAttributes(_:))
    }

    @available(iOS 15, tvOS 15, *)
    func updateWithVideoAttributes(_ videoAttributes: AVAssetVariant.VideoAttributes) {
        if let nominalFrameRate = videoAttributes.nominalFrameRate {
            videoSourceAdvertisedFrameRate = nominalFrameRate as NSNumber
        }

        if videoAttributes.presentationSize != .zero {
            updateWithPresentationSize(videoAttributes.presentationSize)
        }

        if !videoAttributes.codecTypes.isEmpty {
            updateWithVideoCodecTypes(videoAttributes.codecTypes)
        }
    }

    @available(iOS 15, tvOS 15, *)
    static func makeWithRenditionInfo(track: AVAssetTrack, on playerItem: AVPlayerItem) async -> sending Self {
        let videoData = Self()
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
            return videoData
        }

        let videoCodecs = Set<CMVideoCodecType>(
            videoFormatDescriptions
                .map(\.mediaSubType.rawValue)
                .filter { $0 != .zero }
        )

        // Set these right away so they're available even if variants are unavailable or matching fails:
        if let nominalFrameRate {
            videoData.videoSourceAdvertisedFrameRate = nominalFrameRate as NSNumber
        }
        if let presentationSize {
            videoData.updateWithPresentationSize(presentationSize)
        }
        if !videoCodecs.isEmpty {
            videoData.updateWithVideoCodecTypes(Array(videoCodecs))
        }

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
                return videoData
            }
            assetVariants = assetVariantsOrNil
        } catch {
            if !(error is CancellationError) {
                logger.error("Track \(track.trackID): failed to load variants: \(error)")
            }
            return videoData
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
            return videoData
        case 1:
            videoData.updateWithAssetVariant(matchingVariants.first!)
            return videoData
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
            return videoData
        }

        // Effectively handles getting the initial bitrate for a stream, which is an increasingly common use case.
        // There will be one matching entry in the access log, and all further variant info will come from
        // `AVMetricPlayerItemVariantSwitchEvent.toVariant` on iOS 18+.
        if recentBitrates.count == 1 {
            videoData.videoSourceAdvertisedBitrate = recentBitrates.first! as NSNumber
        }

        for bitrate in recentBitrates.reversed() {
            let bitrateMatched = matchingVariants.filter { variant in
                variant.peakBitRate == bitrate
            }
            switch bitrateMatched.count {
            case 0:
                break
            case 1:
                videoData.updateWithAssetVariant(bitrateMatched.first!)
                return videoData
            default:
                videoData.videoSourceAdvertisedBitrate = recentBitrates.first! as NSNumber
                logger.debug("Track \(track.trackID): Multiple matching variants detected after filtering by bitrate=\(bitrate): \(bitrateMatched)")
                return videoData
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
        return videoData
    }
}

