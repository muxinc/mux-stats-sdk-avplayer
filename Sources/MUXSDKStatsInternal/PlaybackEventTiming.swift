import AVFoundation
import CoreMedia.CMSync

struct PlaybackEventTiming: Hashable {
    let mediaTime: CMTime
    let programDate: Date?
    let liveEdgeProgramDate: Date?
}

extension PlaybackEventTiming {
    init(mediaTime: CMTime, programDate: Date?, loadedTimeRanges: some BidirectionalCollection<CMTimeRange>) {
        self.mediaTime = mediaTime
        self.programDate = programDate

        guard let programDate,
              let bufferEnd = loadedTimeRanges.last?.end,
              bufferEnd > mediaTime else {
            liveEdgeProgramDate = nil
            return
        }

        let offset = bufferEnd - mediaTime
        liveEdgeProgramDate = programDate + offset.seconds
    }

    init(playerItem: AVPlayerItem) {
        self.init(
            mediaTime: playerItem.currentTime(),
            programDate: playerItem.currentDate(),
            loadedTimeRanges: playerItem.loadedTimeRanges.lazy.map(\.timeRangeValue))
    }

    @available(iOS 18, tvOS 18, visionOS 2, *)
    init(variantSwitchEvent: AVMetricPlayerItemVariantSwitchEvent, on playerItem: AVPlayerItem) {
        self.init(
            mediaTime: variantSwitchEvent.mediaTime,
            programDate: playerItem.currentDate()
                .flatMap { playerItemProgramDate in
                    let playerItemMediaTime = playerItem.currentTime()
                    let mediaTimeElapsed = (playerItemMediaTime - variantSwitchEvent.mediaTime).seconds
                    guard mediaTimeElapsed >= 0 else {
                        return nil
                    }
                    return playerItemProgramDate - mediaTimeElapsed
                },
            loadedTimeRanges: variantSwitchEvent.loadedTimeRanges)
    }
}
