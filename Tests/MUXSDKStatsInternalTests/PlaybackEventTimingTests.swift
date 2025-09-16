import AVFoundation
import CoreMedia.CMSync
@testable import MUXSDKStatsInternal
import Testing

private class MockableTimingAVPlayerItem: AVPlayerItem {
    nonisolated(unsafe) var getCurrentDate: (() -> Date?)!

    override func currentDate() -> Date? {
        getCurrentDate()
    }

    nonisolated(unsafe) var getCurrentTime: (() -> CMTime)!

    override func currentTime() -> CMTime {
        getCurrentTime()
    }

    nonisolated(unsafe) var getLoadedTimeRanges: (() -> [NSValue])!

    override var loadedTimeRanges: [NSValue] {
        getLoadedTimeRanges()
    }
}

struct PlaybackEventTimingTests {
    @Test(arguments: [
        (CMTime.zero, Date?.none, CMTime?.none,
         PlaybackEventTiming(
            mediaTime: .zero,
            programDate: nil,
            liveEdgeProgramDate: nil)),

        // nil programDate
        (CMTime(seconds: 1, preferredTimescale: 1000), Date?.none, CMTime(seconds: 2, preferredTimescale: 1000),
         PlaybackEventTiming(
            mediaTime: CMTime(seconds: 1, preferredTimescale: 1000),
            programDate: nil,
            liveEdgeProgramDate: nil)),

        // nil bufferEnd
        (CMTime(seconds: 1, preferredTimescale: 1000), Date(timeIntervalSince1970: 100), CMTime?.none,
         PlaybackEventTiming(
            mediaTime: CMTime(seconds: 1, preferredTimescale: 1000),
            programDate: Date(timeIntervalSince1970: 100),
            liveEdgeProgramDate: nil)),

        // typical
        (CMTime(seconds: 1, preferredTimescale: 1000), Date(timeIntervalSince1970: 100), CMTime(seconds: 2, preferredTimescale: 1000),
         PlaybackEventTiming(
            mediaTime: CMTime(seconds: 1, preferredTimescale: 1000),
            programDate: Date(timeIntervalSince1970: 100),
            liveEdgeProgramDate: Date(timeIntervalSince1970: 101))),

        // earlier
        (CMTime(seconds: 1, preferredTimescale: 1000), Date(timeIntervalSince1970: 100), CMTime(seconds: 0, preferredTimescale: 1000),
         PlaybackEventTiming(
            mediaTime: CMTime(seconds: 1, preferredTimescale: 1000),
            programDate: Date(timeIntervalSince1970: 100),
            liveEdgeProgramDate: nil)),
    ])
    func bufferEndInit(mediaTime: CMTime, programDate: Date?, bufferEnd: CMTime?, expected: PlaybackEventTiming) async throws {
        let actual = PlaybackEventTiming(mediaTime: mediaTime, programDate: programDate, bufferEnd: bufferEnd)
        #expect(actual.mediaTime == expected.mediaTime)
        #expect(actual.programDate == expected.programDate)
        #expect(actual.liveEdgeProgramDate == expected.liveEdgeProgramDate)
        #expect(actual == expected)
    }

    @Test
    func inferredProgramDateOnAVPlayerItem() async {
        let playerItem = await MainActor.run { MockableTimingAVPlayerItem(url: URL(string: "https://example.com")!) }
        playerItem.getCurrentDate = { Date(timeIntervalSince1970: 101) }
        playerItem.getCurrentTime = { CMTime(seconds: 2, preferredTimescale: 1000) }

        let programDate = await playerItem.inferProgramDate(at: CMTime(seconds: 1, preferredTimescale: 1000))
        #expect(programDate == Date(timeIntervalSince1970: 100))
    }

    @Test
    func playerItemCurrentTimingPaused() async {
        let playerItem = await MainActor.run { MockableTimingAVPlayerItem(url: URL(string: "https://example.com")!) }
        playerItem.getCurrentDate = { Date(timeIntervalSince1970: 101) }
        playerItem.getCurrentTime = { CMTime(seconds: 1, preferredTimescale: 1000) }
        playerItem.getLoadedTimeRanges = { [NSValue(timeRange: CMTimeRange(start: .zero, end: CMTime(seconds: 3, preferredTimescale: 1000)))] }

        let timing = await playerItem.currentTiming()

        let expected = PlaybackEventTiming(
            mediaTime: CMTime(seconds: 1, preferredTimescale: 1000),
            programDate: Date(timeIntervalSince1970: 101),
            liveEdgeProgramDate: Date(timeIntervalSince1970: 103))

        #expect(timing == expected)
    }

    @Test
    func playerItemCurrentTimingPausedNoLoadedTimeRanges() async {
        let playerItem = await MainActor.run { MockableTimingAVPlayerItem(url: URL(string: "https://example.com")!) }
        playerItem.getCurrentDate = { Date(timeIntervalSince1970: 101) }
        playerItem.getCurrentTime = { CMTime(seconds: 1, preferredTimescale: 1000) }
        playerItem.getLoadedTimeRanges = { [] }

        let timing = await playerItem.currentTiming()

        let expected = PlaybackEventTiming(
            mediaTime: CMTime(seconds: 1, preferredTimescale: 1000),
            programDate: Date(timeIntervalSince1970: 101),
            liveEdgeProgramDate: nil)

        #expect(timing == expected)
    }

    @Test
    func playerItemCurrentTimingWhileTimeAdvancing() async {
        let playerItem = await MainActor.run { MockableTimingAVPlayerItem(url: URL(string: "https://example.com")!) }
        // initial call:
        let mediaTime = CMTime(seconds: 1, preferredTimescale: 1000)
        // in background, immediately after getting currentDate:
        let mediaTimeAfter = CMTime(seconds: 2, preferredTimescale: 1000)
        var currentTime = mediaTime
        playerItem.getCurrentDate = {
            defer { currentTime = mediaTimeAfter }
            return Date(timeIntervalSince1970: 104)
        }
        playerItem.getCurrentTime = { currentTime }
        // corresponds to date range 102..<105
        playerItem.getLoadedTimeRanges = { [NSValue(timeRange: CMTimeRange(start: .zero, end: CMTime(seconds: 3, preferredTimescale: 1000)))] }

        let timing = await playerItem.currentTiming()

        let expected = PlaybackEventTiming(
            mediaTime: CMTime(seconds: 1, preferredTimescale: 1000),
            programDate: Date(timeIntervalSince1970: 103),
            liveEdgeProgramDate: Date(timeIntervalSince1970: 105))

        #expect(timing == expected)
    }
}
