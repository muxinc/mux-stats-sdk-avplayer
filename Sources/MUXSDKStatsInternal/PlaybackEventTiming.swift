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
              let currentDate = playerItem.currentDate() else {
            // Preserve behavior from MUXSDKPlayerBinding: these are only set on live streams
            programTime = nil
            liveEdgeProgramTime = nil
            return
        }

        programTime = currentDate

        guard let bufferEnd = playerItem.loadedTimeRanges.last?.timeRangeValue.end,
              bufferEnd > mediaTime else {
            liveEdgeProgramTime = nil
            return
        }

        let offset = bufferEnd - mediaTime
        liveEdgeProgramTime = DateInterval(start: currentDate, duration: offset.seconds).end
    }
}
