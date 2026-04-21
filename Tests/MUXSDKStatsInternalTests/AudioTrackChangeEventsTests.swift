import AudioToolbox
import CoreMedia
import MuxCore
@testable import MUXSDKStatsInternal
import Testing

struct AudioTrackChangeEventsTests {
    @Test(arguments: [
        (1, AudioChannelLayoutTag?.none, MUXSDKAudioTrackChannelLayout.mono),
        (2, AudioChannelLayoutTag?.none, MUXSDKAudioTrackChannelLayout.stereo),
        (6, AudioChannelLayoutTag?.none, MUXSDKAudioTrackChannelLayout.fivePointOne),
        (8, AudioChannelLayoutTag?.none, MUXSDKAudioTrackChannelLayout.sevenPointOne),
        (3, AudioChannelLayoutTag?.none, MUXSDKAudioTrackChannelLayout("3")),
        (2, kAudioChannelLayoutTag_Atmos_5_1_2, MUXSDKAudioTrackChannelLayout.atmos),
    ])
    func channelLayoutMapping(
        channelCount: Int,
        layoutTag: AudioChannelLayoutTag?,
        expected: MUXSDKAudioTrackChannelLayout?
    ) {
        guard #available(iOS 15, tvOS 15, *) else {
            return
        }

        #expect(
            AudioTrackChangeEvents.AssetTrackInfo.channelLayout(
                channelCount: channelCount,
                audioChannelLayoutTag: layoutTag
            ) == expected
        )
    }

    @Test(arguments: [
        (AudioFormatID(kAudioFormatAC3), "ac-3"),
        (AudioFormatID(kAudioFormatEnhancedAC3), "ec-3"),
        (AudioFormatID(kAudioFormatMPEG4AAC), "mp4a.40.2"),
        (AudioFormatID(kAudioFormatMPEG4AAC_HE), "mp4a.40.5"),
        (AudioFormatID(kAudioFormatMPEG4AAC_HE_V2), "mp4a.40.29"),
        (AudioFormatID(kAudioFormatMPEGD_USAC), "mp4a.40.42"),
        (AudioFormatID(kAudioFormatOpus), "opus"),
        (AudioFormatID(kAudioFormatAppleLossless), nil),
    ])
    func codecMapping(formatID: AudioFormatID, expected: String?) {
        guard #available(iOS 15, tvOS 15, *) else {
            return
        }

        #expect(AudioTrackChangeEvents.AssetTrackInfo.codecString(for: formatID) == expected)
    }

    @Test
    func disabledEventOmitsOptionalMetadata() throws {
        guard #available(iOS 15, tvOS 15, *) else {
            return
        }

        let event = MUXSDKAudioTrackChangeEvent(
            timing: PlaybackEventTiming(
                mediaTime: .zero,
                programDate: nil,
                liveEdgeProgramDate: nil),
            trackInfo: nil)

        let playerData = try #require(event.playerData)

        #expect(event.playerAudioTrackEnabled as? Bool == false)
        #expect(event.playerAudioTrackName == nil)
        #expect(event.playerAudioTrackLanguage == nil)
        #expect(event.playerAudioTrackCodec == nil)
        #expect(event.playerAudioTrackBitrate == nil)
        #expect(event.playerAudioTrackChannels == nil)
        #expect(playerData.playerAudioTrackEnabled as? Bool == false)
    }

    @Test
    func selectedEventPreservesAllExtractedMetadata() throws {
        guard #available(iOS 15, tvOS 15, *) else {
            return
        }

        let event = MUXSDKAudioTrackChangeEvent(
            audioTrackEnabled: true as NSNumber,
            audioTrackName: "English",
            audioTrackLanguage: "en-US",
            audioTrackCodec: "ec-3",
            audioTrackBitrate: 128_000,
            audioTrackChannels: MUXSDKAudioTrackChannelLayout.stereo)

        event.updateWithTiming(
            PlaybackEventTiming(
                mediaTime: CMTime(seconds: 12.345, preferredTimescale: 1000),
                programDate: Date(timeIntervalSince1970: 100),
                liveEdgeProgramDate: nil))

        let playerData = try #require(event.playerData)

        #expect(event.playerAudioTrackEnabled as? Bool == true)
        #expect(event.playerAudioTrackName == "English")
        #expect(event.playerAudioTrackLanguage == "en-US")
        #expect(event.playerAudioTrackCodec == "ec-3")
        #expect(event.playerAudioTrackBitrate?.intValue == 128_000)
        #expect(event.playerAudioTrackChannels == MUXSDKAudioTrackChannelLayout.stereo)
        #expect(playerData.playerAudioTrackEnabled as? Bool == true)
        #expect(playerData.playerAudioTrackName == "English")
        #expect(playerData.playerAudioTrackLanguage == "en-US")
        #expect(playerData.playerAudioTrackCodec == "ec-3")
        #expect(playerData.playerAudioTrackBitrate?.intValue == 128_000)
        #expect(playerData.playerAudioTrackChannels == MUXSDKAudioTrackChannelLayout.stereo)
        #expect(playerData.playerPlayheadTime?.intValue == 12_345)
    }
}
