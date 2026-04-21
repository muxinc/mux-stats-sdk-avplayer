import AVFoundation
@preconcurrency import MuxCore
@testable import MUXSDKStatsInternal
import Testing

// has cc and subtitle track
let bipBopExampleURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")!

struct TextTrackChangeEventsTests {

    @available(iOS 15, tvOS 15, *)
    @Test func initialEventPreloadOnPlayerItem() async throws {
        try await confirmation("an initial event should fire when added to unloaded item", expectedCount: 1) { confirmation in
            let player = AVPlayer()
            player.appliesMediaSelectionCriteriaAutomatically = false
            let playerItem = AVPlayerItem(url: bipBopExampleURL)

            try await { @MainActor in
                let group = try #require(await playerItem.asset.loadMediaSelectionGroup(for: .legible))
                let ccOption = try #require(group.options.first(where: { $0.mediaType == .closedCaption }))
                playerItem.select(ccOption, in: group)
            }()

            let ttce = TextTrackChangeEvents(playerItem: playerItem)

            let events = ttce.allEvents()
                .handleEvents(receiveOutput: { _ in confirmation() })
                .buffer(size: 10, prefetch: .byRequest, whenFull: .dropOldest)
                .values

            var iterator = events.makeAsyncIterator()

            player.replaceCurrentItem(with: playerItem)

            try await playerItem.waitForReadyToPlay()

            let event = try #require(await iterator.next())
            #expect(event.playerData?.playerPlayheadTime == 0 as NSNumber)
            #expect(event.playerTextTrackEnabled == true as NSNumber)
            #expect(event.playerTextTrackName == "English")
            #expect(event.playerTextTrackType == .closedCaptions)
            #expect(event.playerTextTrackFormat == .cea608)
            #expect(event.playerTextTrackLanguage == "en")
        }
    }

    @available(iOS 15, tvOS 15, *)
    @Test func emptyInitialEventPreloadOnPlayerItem() async throws {
        try await confirmation("an initial event should fire when added to unloaded item", expectedCount: 1) { confirmation in
            let player = AVPlayer()
            player.appliesMediaSelectionCriteriaAutomatically = false
            let playerItem = AVPlayerItem(url: bipBopExampleURL)

            try await { @MainActor in
                let group = try #require(await playerItem.asset.loadMediaSelectionGroup(for: .legible))
                playerItem.select(nil, in: group)
            }()

            let ttce = TextTrackChangeEvents(playerItem: playerItem)

            let events = ttce.allEvents()
                .handleEvents(receiveOutput: { _ in confirmation() })
                .buffer(size: 10, prefetch: .byRequest, whenFull: .dropOldest)
                .values

            var iterator = events.makeAsyncIterator()

            player.replaceCurrentItem(with: playerItem)

            try await playerItem.waitForReadyToPlay()

            let event = try #require(await iterator.next())
            #expect(event.playerData?.playerPlayheadTime == 0 as NSNumber)
            #expect(event.playerTextTrackEnabled == false as NSNumber)
            #expect(event.playerTextTrackName == nil)
            #expect(event.playerTextTrackType == nil)
            #expect(event.playerTextTrackFormat == nil)
            #expect(event.playerTextTrackLanguage == nil)
        }
    }

    @available(iOS 15, tvOS 15, *)
    @Test func initialEventOnReadyItem() async throws {
        try await confirmation("an initial event should fire when added to ready item", expectedCount: 1) { confirmation in
            let player = AVPlayer()
            player.appliesMediaSelectionCriteriaAutomatically = false
            let playerItem = AVPlayerItem(url: bipBopExampleURL)

            try await { @MainActor in
                let group = try #require(await playerItem.asset.loadMediaSelectionGroup(for: .legible))
                let ccOption = try #require(group.options.first(where: { $0.mediaType == .closedCaption }))
                playerItem.select(ccOption, in: group)
            }()

            player.replaceCurrentItem(with: playerItem)

            try await playerItem.waitForReadyToPlay()

            let ttce = TextTrackChangeEvents(playerItem: playerItem)

            let events = ttce.allEvents()
                .handleEvents(receiveOutput: { _ in confirmation() })
                .buffer(size: 10, prefetch: .byRequest, whenFull: .dropOldest)
                .values

            var iterator = events.makeAsyncIterator()

            let event = try #require(await iterator.next())
            #expect(event.playerData?.playerPlayheadTime == 0 as NSNumber)
            #expect(event.playerTextTrackEnabled == true as NSNumber)
            #expect(event.playerTextTrackName == "English")
            #expect(event.playerTextTrackType == .closedCaptions)
            #expect(event.playerTextTrackFormat == .cea608)
            #expect(event.playerTextTrackLanguage == "en")
        }
    }

    @available(iOS 15, tvOS 15, *)
    @Test func emptyInitialEventOnReadyItem() async throws {
        try await confirmation("an initial event should fire when added to ready item", expectedCount: 1) { confirmation in
            let player = AVPlayer()
            player.appliesMediaSelectionCriteriaAutomatically = false
            let playerItem = AVPlayerItem(url: bipBopExampleURL)

            try await { @MainActor in
                let group = try #require(await playerItem.asset.loadMediaSelectionGroup(for: .legible))
                playerItem.select(nil, in: group)
            }()

            player.replaceCurrentItem(with: playerItem)

            try await playerItem.waitForReadyToPlay()

            let ttce = TextTrackChangeEvents(playerItem: playerItem)

            let events = ttce.allEvents()
                .handleEvents(receiveOutput: { _ in confirmation() })
                .buffer(size: 10, prefetch: .byRequest, whenFull: .dropOldest)
                .values

            var iterator = events.makeAsyncIterator()

            let event = try #require(await iterator.next())
            #expect(event.playerData?.playerPlayheadTime == 0 as NSNumber)
            #expect(event.playerTextTrackEnabled == false as NSNumber)
            #expect(event.playerTextTrackName == nil)
            #expect(event.playerTextTrackType == nil)
            #expect(event.playerTextTrackFormat == nil)
            #expect(event.playerTextTrackLanguage == nil)
        }
    }

    @available(iOS 15, tvOS 15, *)
    @Test func initialEventOnPlayingItem() async throws {
        try await confirmation("an initial event should fire when added to a playing item", expectedCount: 1) { confirmation in
            let player = AVPlayer()
            player.appliesMediaSelectionCriteriaAutomatically = false
            let playerItem = AVPlayerItem(url: bipBopExampleURL)

            try await { @MainActor in
                let group = try #require(await playerItem.asset.loadMediaSelectionGroup(for: .legible))
                let ccOption = try #require(group.options.first(where: { $0.mediaType == .closedCaption }))
                playerItem.select(ccOption, in: group)
            }()

            player.replaceCurrentItem(with: playerItem)

            try await playerItem.waitForReadyToPlay()

            await MainActor.run {
                player.play()
            }

            try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)

            let timeBeforeAttach = try #require(playerItem.currentTime().muxTimeValue)

            let ttce = TextTrackChangeEvents(playerItem: playerItem)

            let events = ttce.allEvents()
                .handleEvents(receiveOutput: { _ in confirmation() })
                .buffer(size: 10, prefetch: .byRequest, whenFull: .dropOldest)
                .values

            var iterator = events.makeAsyncIterator()

            let event = try #require(await iterator.next())
            let playheadTime = try #require(event.playerData?.playerPlayheadTime)
            #expect(playheadTime.compare(timeBeforeAttach) != .orderedAscending)
            #expect(event.playerTextTrackEnabled == true as NSNumber)
            #expect(event.playerTextTrackName == "English")
            #expect(event.playerTextTrackType == .closedCaptions)
            #expect(event.playerTextTrackFormat == .cea608)
            #expect(event.playerTextTrackLanguage == "en")
        }
    }

    @available(iOS 15, tvOS 15, *)
    @Test func changeEventIsFired() async throws {
        try await confirmation("three events are fired", expectedCount: 3) { confirmation in
            let player = AVPlayer()
            player.appliesMediaSelectionCriteriaAutomatically = false
            let playerItem = AVPlayerItem(url: bipBopExampleURL)

            try await { @MainActor in
                let group = try #require(await playerItem.asset.loadMediaSelectionGroup(for: .legible))
                playerItem.select(nil, in: group)
            }()

            player.replaceCurrentItem(with: playerItem)

            let ttce = TextTrackChangeEvents(playerItem: playerItem)

            let events = ttce.allEvents()
                .handleEvents(receiveOutput: { _ in confirmation() })
                .buffer(size: 10, prefetch: .byRequest, whenFull: .dropOldest)
                .values

            var iterator = events.makeAsyncIterator()

            await MainActor.run {
                player.play()
            }

            let firstEvent = try #require(await iterator.next())
            #expect(firstEvent.playerData?.playerPlayheadTime == 0 as NSNumber)
            #expect(firstEvent.playerTextTrackEnabled == false as NSNumber)
            #expect(firstEvent.playerTextTrackName == nil)
            #expect(firstEvent.playerTextTrackType == nil)
            #expect(firstEvent.playerTextTrackFormat == nil)
            #expect(firstEvent.playerTextTrackLanguage == nil)

            try await Task.sleep(nanoseconds: NSEC_PER_SEC/2)

            let timeBeforeSecondEvent = try await { @MainActor in
                let group = try #require(await playerItem.asset.loadMediaSelectionGroup(for: .legible))
                let ccOption = try #require(group.options.first(where: { $0.mediaType == .closedCaption }))
                defer {
                    playerItem.select(ccOption, in: group)
                }
                return try #require(playerItem.currentTime().muxTimeValue)
            }()

            let secondEvent = try #require(await iterator.next())
            #expect(try #require(secondEvent.playerData?.playerPlayheadTime).compare(timeBeforeSecondEvent) != .orderedAscending)
            #expect(secondEvent.playerTextTrackEnabled == true as NSNumber)
            #expect(secondEvent.playerTextTrackName == "English")
            #expect(secondEvent.playerTextTrackType == .closedCaptions)
            #expect(secondEvent.playerTextTrackFormat == .cea608)
            #expect(secondEvent.playerTextTrackLanguage == "en")

            try await Task.sleep(nanoseconds: NSEC_PER_SEC/2)

            let timeBeforeThirdEvent = try await { @MainActor in
                let group = try #require(await playerItem.asset.loadMediaSelectionGroup(for: .legible))
                let subtitleOption = try #require(group.options.first(where: { $0.mediaType == .subtitle }))
                defer {
                    playerItem.select(subtitleOption, in: group)
                }
                return try #require(playerItem.currentTime().muxTimeValue)
            }()

            let thirdEvent = try #require(await iterator.next())
            #expect(try #require(thirdEvent.playerData?.playerPlayheadTime).compare(timeBeforeThirdEvent) != .orderedAscending)
            #expect(thirdEvent.playerTextTrackEnabled == true as NSNumber)
            #expect(thirdEvent.playerTextTrackName == "English")
            #expect(thirdEvent.playerTextTrackType == .subtitles)
            // This matching occasionally fails, so the value can be missing but must not be incorrect:
            #expect([.webVTT, nil].contains(thirdEvent.playerTextTrackFormat))
            #expect(thirdEvent.playerTextTrackLanguage == "en")
        }
    }
}
