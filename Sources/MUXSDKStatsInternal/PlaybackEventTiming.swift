import AVFoundation
import CoreMedia.CMSync

struct PlaybackEventTiming: Hashable {
    let mediaTime: CMTime
    let programTime: Date?
    let liveEdgeProgramTime: Date?
}

extension PlaybackEventTiming {
    init(playerItem: AVPlayerItem) {
        mediaTime = playerItem.currentTime()

        guard playerItem.duration.isIndefinite,
              let programTime = playerItem.currentDate() else {
            // Preserve behavior from MUXSDKPlayerBinding: these are only set on live streams
            programTime = nil
            liveEdgeProgramTime = nil
            return
        }

        self.programTime = programTime

        guard let bufferEnd = playerItem.loadedTimeRanges.last?.timeRangeValue.end,
              bufferEnd > mediaTime else {
            liveEdgeProgramTime = nil
            return
        }

        let offset = bufferEnd - mediaTime
        liveEdgeProgramTime = DateInterval(start: programTime, duration: offset.seconds).end
    }

    @available(iOS 18, tvOS 18, *)
    init(variantSwitchEvent: AVMetricPlayerItemVariantSwitchEvent, on playerItem: AVPlayerItem) {
        mediaTime = variantSwitchEvent.mediaTime

        guard playerItem.duration.isIndefinite,
              let playerItemProgramTime = playerItem.currentDate() else {
            // Preserve behavior from MUXSDKPlayerBinding: these are only set on live streams
            programTime = nil
            liveEdgeProgramTime = nil
            return
        }

        let playerItemMediaTime = playerItem.currentTime()

        let mediaTimeElapsed = (playerItemMediaTime - mediaTime).seconds

        let programTime = DateInterval(start: playerItemProgramTime, duration: -mediaTimeElapsed).end
        self.programTime = programTime

        guard let bufferEnd = variantSwitchEvent.loadedTimeRanges.last?.end,
              bufferEnd > mediaTime else {
            liveEdgeProgramTime = nil
            return
        }

        let offset = bufferEnd - mediaTime
        liveEdgeProgramTime = DateInterval(start: programTime, duration: offset.seconds).end
    }
}
