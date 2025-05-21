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
        videoSourceAdvertisedBitrate = assetVariant.averageBitRate as NSNumber?
        videoSourceAdvertisedFrameRate = assetVariant.videoAttributes?.nominalFrameRate as NSNumber?

        if let presentationSize = assetVariant.videoAttributes?.presentationSize, presentationSize != .zero {
            updateWithPresentationSize(presentationSize)
        }
    }

    @available(iOS 15, tvOS 15, *)
    static func renditionVideoData(for playerItem: AVPlayerItem, track: AVAssetTrack?) async -> MUXSDKVideoData {
        async let assetVariants = (playerItem.asset as? AVURLAsset)?.load(.variants)
        async let assetDuration = playerItem.asset.load(.duration)
        // This is less exact and only used after all other variant matching options are exhausted
        async let indicatedBitrate = playerItem.mostRecentIndicatedBitrate

        let videoData = MUXSDKVideoData()

        if let track, let (
            naturalSizeOrZero,
            nominalFrameRateOrZero,
            formatDescriptions
        ) = try? await track.load(
            .naturalSize,
            .nominalFrameRate,
            .formatDescriptions
        ) {
            let trackNominalFrameRate = nominalFrameRateOrZero == .zero ? nil : nominalFrameRateOrZero
            let trackSize = naturalSizeOrZero == .zero ? nil : naturalSizeOrZero
            let trackVideoFormatDescriptions = formatDescriptions.filter { $0.mediaType == .video }
            let trackVideoCodecs = Set(
                trackVideoFormatDescriptions
                    .map(\.mediaSubType.rawValue)
                    .filter { $0 != .zero }
            )

            // Set these right away so they're available even if variants are unavailable or matching fails:
            videoData.videoSourceAdvertisedFrameRate = trackNominalFrameRate as NSNumber?
            trackSize.map(videoData.updateWithPresentationSize(_:))

            if let assetVariants = try? await assetVariants, !assetVariants.isEmpty {
                let matchingVariants = assetVariants.filter { variant in
                    guard let videoAttributes = variant.videoAttributes else {
                        return false
                    }

                    if let trackSize {
                        guard videoAttributes.presentationSize != .zero, videoAttributes.presentationSize == trackSize else {
                            return false
                        }
                    }

                    if let trackNominalFrameRate, let variantNominalFrameRate = videoAttributes.nominalFrameRate {
                        guard trackNominalFrameRate == Float(variantNominalFrameRate) else {
                            return false
                        }
                    }

                    if !videoAttributes.codecTypes.isEmpty, !trackVideoCodecs.isEmpty {
                        guard !trackVideoCodecs.isDisjoint(with: videoAttributes.codecTypes) else {
                            return false
                        }
                    }

                    return true
                }

                switch matchingVariants.count {
                case 0:
                    logger.error("Track \(track.trackID): No matching variants detected by basic video attributes")
                case 1:
                    videoData.updateWithAssetVariant(matchingVariants.first!)
                    logger.debug("Track \(track.trackID): variant bitrate: \(matchingVariants.first!.averageBitRate?.description ?? "nil")")
                default:
                    // Separate, last-ditch procedure here as this access log process is less exact.

                    if let indicatedBitrate = try? await indicatedBitrate {
                        let matchingVariants = matchingVariants.filter { variant in
                            variant.averageBitRate == nil || variant.averageBitRate == indicatedBitrate
                        }
                        switch matchingVariants.count {
                        case 0:
                            logger.error("Track \(track.trackID): No matching variants detected by bitrate")
                        case 1:
                            videoData.updateWithAssetVariant(matchingVariants.first!)
                        default:
                            logger.error("Track \(track.trackID): Multiple matching variants detected: \(matchingVariants)")
                        }
                    } else {
                        logger.error("Track \(track.trackID): Multiple matching variants detected: \(matchingVariants)")
                    }
                }
            }
        }

        (try? await assetDuration).map(videoData.updateWithAssetDuration(_:))

        return videoData
    }
}

