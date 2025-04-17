import AVFoundation
import MuxCore

extension MUXSDKVideoData {
    func updateWithAssetDuration(_ duration: CMTime) {
        let isLive = duration.isIndefinite
        videoSourceIsLive = isLive ? "true" : "false"
        if !isLive && !duration.seconds.isZero {
            videoSourceDuration = duration.seconds as NSNumber
        }
    }

    func updateWithPresentationSize(_ presentationSize: CGSize) {
        videoSourceHeight = presentationSize.height as NSNumber
        videoSourceWidth = presentationSize.width as NSNumber
    }

    @available(iOS 15, tvOS 15, *)
    func updateWithAssetVariant(_ assetVariant: AVAssetVariant) {
        if let averageBitRate = assetVariant.averageBitRate {
            videoSourceAdvertisedBitrate = averageBitRate as NSNumber
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

        // TODO: videoAttributes.codecTypes
    }

    @available(iOS 15, tvOS 15, *)
    func updateWithRenditionInfo(track: AVAssetTrack, on playerItem: AVPlayerItem) async {
        // This is less exact and only used after all other variant matching options are exhausted
        // Still obtain it immediately in case another variant switch happens
        // TODO: add timeout here?
        async let bitratesFromAccessLog = playerItem.indicatedBitratesInAccessLog
        // Start loading this early:
        async let assetVariantsOrNil = (playerItem.asset as? AVURLAsset)?.load(.variants)

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
            return
        }

        let videoCodecs = Set<CMVideoCodecType>(
            videoFormatDescriptions
                .map(\.mediaSubType.rawValue)
                .filter { $0 != .zero }
        )

        // Set these right away so they're available even if variants are unavailable or matching fails:
        if let nominalFrameRate {
            videoSourceAdvertisedFrameRate = nominalFrameRate as NSNumber
        }
        if let presentationSize {
            updateWithPresentationSize(presentationSize)
        }
        if !videoCodecs.isEmpty {
            // TODO: videoSourceAdvertisedCodec
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
                return
            }
            assetVariants = assetVariantsOrNil
        } catch {
            if !(error is CancellationError) {
                logger.error("Track \(track.trackID): failed to load variants: \(error)")
            }
            return
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
            return
        case 1:
            updateWithAssetVariant(matchingVariants.first!)
            return
        default:
            break
        }

        // Separate, last-ditch procedure here as this access log process can be less exact.
        logger.debug("Track \(track.trackID): Attempting to match variant by recent indicated bitrates in access log")

        let recentBitrates: [Double]

        do {
            recentBitrates = try await bitratesFromAccessLog.suffix(3)
        } catch {
            if !(error is CancellationError) {
                logger.error("Track \(track.trackID): failed to load bitrates from access log: \(error)")
            }
            return
        }

        // Effectively handles getting the initial bitrate for a stream, which is an increasingly common use case.
        // There will be one matching entry in the access log, and all further variant info will come from
        // `AVMetricPlayerItemVariantSwitchEvent.toVariant` on iOS 18+.
        if recentBitrates.count == 1 {
            videoSourceAdvertisedBitrate = recentBitrates.first! as NSNumber
        }

        for bitrate in recentBitrates.reversed() {
            let bitrateMatched = matchingVariants.filter { variant in
                variant.peakBitRate == bitrate
            }
            switch bitrateMatched.count {
            case 0:
                break
            case 1:
                updateWithAssetVariant(bitrateMatched.first!)
                return
            default:
                videoSourceAdvertisedBitrate = recentBitrates.first! as NSNumber
                logger.debug("Track \(track.trackID): Multiple matching variants detected after filtering by bitrate=\(bitrate): \(bitrateMatched)")
                return
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
    }

    @available(iOS 15, tvOS 15, *)
    static func renditionVideoData(track: AVAssetTrack, on playerItem: AVPlayerItem) async -> MUXSDKVideoData {
        let videoData = MUXSDKVideoData()

        await videoData.updateWithRenditionInfo(track: track, on: playerItem)

        return videoData
    }
}

