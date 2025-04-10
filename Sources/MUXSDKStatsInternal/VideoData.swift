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

    @available(iOS 15, tvOS 15, *)
    func updateWithAssetVariant(_ assetVariant: AVAssetVariant) {
        videoSourceAdvertisedBitrate = assetVariant.averageBitRate as NSNumber?
        videoSourceAdvertisedFrameRate = assetVariant.videoAttributes?.nominalFrameRate as NSNumber?

        if let presentationSize = assetVariant.videoAttributes?.presentationSize {
            videoSourceHeight = presentationSize.height as NSNumber
            videoSourceWidth = presentationSize.width as NSNumber
        }
    }
}
