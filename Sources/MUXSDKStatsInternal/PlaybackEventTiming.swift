import AVFoundation
import CoreMedia.CMSync

struct PlaybackEventTiming: Sendable, Hashable {
    let mediaTime: CMTime
    let programDate: Date?
    let liveEdgeProgramDate: Date?

    init(mediaTime: CMTime, programDate: Date?, liveEdgeProgramDate: Date?) {
        self.mediaTime = mediaTime
        self.programDate = programDate
        self.liveEdgeProgramDate = liveEdgeProgramDate
    }
}

extension PlaybackEventTiming {
    init(mediaTime: CMTime, programDate: Date?, bufferEnd: CMTime?) {
        self.mediaTime = mediaTime
        self.programDate = programDate

        guard let programDate,
              let bufferEnd,
              bufferEnd > mediaTime else {
            liveEdgeProgramDate = nil
            return
        }

        let offset = bufferEnd - mediaTime
        liveEdgeProgramDate = programDate + offset.seconds
    }
}

@available(iOS 13, tvOS 13, *)
extension AVPlayerItem {
    nonisolated private func inferProgramDateSync(at mediaTime: CMTime) -> Date? {
        // currentDate() can block the calling thread, for example while waiting for
        // the variant playlist containing the EXT-X-PROGRAM-DATE-TIME tag
        currentDate()
            .flatMap { currentDate in
                let mediaTimeElapsed = currentTime() - mediaTime
                guard mediaTimeElapsed.isNumeric else {
                    return nil
                }
                return currentDate - mediaTimeElapsed.seconds
            }
    }

    nonisolated func inferProgramDate(at mediaTime: CMTime) async -> Date? {
        await Task {
            inferProgramDateSync(at: mediaTime)
        }.value
    }

    nonisolated func currentTiming() async -> PlaybackEventTiming {
        let mediaTime = currentTime()
        let bufferEnd = loadedTimeRanges.last?.timeRangeValue.end
        return PlaybackEventTiming(
            mediaTime: mediaTime,
            programDate: await inferProgramDate(at: mediaTime),
            bufferEnd: bufferEnd)
    }
}

@available(iOS 18, tvOS 18, visionOS 2, *)
extension PlaybackEventTiming {
    init(variantSwitchEvent: AVMetricPlayerItemVariantSwitchEvent, on playerItem: AVPlayerItem) async {
        await self.init(
            mediaTime: variantSwitchEvent.mediaTime,
            programDate: playerItem.inferProgramDate(at: variantSwitchEvent.mediaTime),
            bufferEnd: variantSwitchEvent.loadedTimeRanges.last?.end)
    }
}
