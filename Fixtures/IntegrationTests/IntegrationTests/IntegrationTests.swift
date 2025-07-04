import Testing
@testable import MUXSDKStats
import Swifter

@Suite
struct IntegrationTests {
    let dispatchDelay = 3.0
    let msTolerance: Double = 2000
    
    func getLastTimestamp(for playerName: String) -> NSNumber? {
        return MUXSDKCore.getPlayheadTimeStamps(forPlayer: playerName).last
    }
    
    func getTimeDeltas(for playerName: String) -> [NSNumber] {
        return MUXSDKCore.getPlayheadTimeDeltas(forPlayer: playerName)
    }
    
    func getEventsAndReset(for playerName: String) -> [MUXSDKBaseEvent]? {
        defer {
//            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        return MUXSDKCore.getEventsForPlayer(playerName)
    }
    
    func assertStartPlaying(with player: AVPlayer, for playerName: String) async {
        NSLog("## Start playing content")
        await MainActor.run {
            player.play()
        }
        try? await Task.sleep(nanoseconds: UInt64(dispatchDelay * 1_000_000_000))
        
        let events = getEventsAndReset(for: playerName)
        
        let containsPlayEvent = events?.contains { $0 is MUXSDKPlayEvent } ?? false
        
        // Expect that MUXSDKPlayEvent was sent
        #expect(containsPlayEvent)
    }
    
    func assertWaitForNSeconds(n seconds: Double, with player: AVPlayer, for playerName: String) {
        NSLog("## Wait approximately \(seconds) seconds")
        let waitTimeBefore = getLastTimestamp(for: playerName)!.doubleValue
        let beforeTimePlayer = player.currentTime().seconds
        
        var currentTimePlayer = player.currentTime().seconds
        var waitedTime = 0.0
        while((currentTimePlayer - beforeTimePlayer) < seconds) {
            Thread.sleep(forTimeInterval: 0.1)
            waitedTime += 0.1
            currentTimePlayer = player.currentTime().seconds
            
            guard waitedTime < seconds * 2 else {
                Issue.record("Expected to wait \(seconds) but player stalled for \(waitedTime) seconds, at \(currentTimePlayer - beforeTimePlayer )")
                return
            }
        }
        
        let waitTimeAfter = getLastTimestamp(for: playerName)!.doubleValue
        let waitTimeDiff = waitTimeAfter - waitTimeBefore
        let lowerBound = (seconds * 1000) - msTolerance
        let upperBound = (seconds * 1000) + msTolerance
        
        // Expect that time difference is approximately n seconds
        #expect(waitTimeDiff >= lowerBound && waitTimeDiff <= upperBound, "Waited \(waitTimeDiff)ms, expected between \(lowerBound)ms and \(upperBound)ms")
    }
    
    func assertPauseForNSeconds(n seconds: Double, with player: AVPlayer, for playerName: String) async {
        NSLog("## Pause the content for \(seconds) seconds")
        let waitTimeBefore = getLastTimestamp(for: playerName)!.doubleValue
        await MainActor.run {
            player.pause()
        }
        try? await Task.sleep(nanoseconds: UInt64(dispatchDelay * 1_000_000_000))
        let waitTimeAfter = getLastTimestamp(for: playerName)!.doubleValue
        
        let waitTimeDiff = waitTimeAfter - waitTimeBefore
        // Expect that time difference is approximately 0 seconds
        #expect(waitTimeDiff >= 0 && waitTimeDiff < msTolerance)
        
        let events = getEventsAndReset(for: playerName)
        let containsPauseEvent = events?.contains { $0 is MUXSDKPauseEvent } ?? false
        // Expect that MUXSDKPauseEvent was sent
        #expect(containsPauseEvent)
    }
    
    func assertSeekNSeconds(n seconds: Double, with player: AVPlayer, for playerName: String) {
        NSLog("## Seek \(seconds) seconds")
        let currentTime = player.currentTime()
        let seekTime = CMTime(seconds: currentTime.seconds + seconds, preferredTimescale: 1000)
        player.seek(to: seekTime)
        Thread.sleep(forTimeInterval: dispatchDelay)
        
        // Expect that MUXSDKSeekEvent was sent
        let events = getEventsAndReset(for: playerName)
        let containsSeekEvent = events?.contains { $0 is MUXSDKSeekedEvent || $0 is MUXSDKInternalSeekingEvent } ?? false
        #expect(containsSeekEvent)
        
        // Expect that time has gone forwards approximately n seconds
        let timeDeltas = getTimeDeltas(for: playerName)
        
        let expectedDelta = seconds * 1000
        
        let hasSeekDelta = timeDeltas.contains {
            let diff = ($0).doubleValue
            return abs(diff - expectedDelta) <= msTolerance
        }
        
        #expect(hasSeekDelta, "Expected a delta close to \(expectedDelta)ms, but none was found")
    }
    
    func assertFinishPlaying(timeLeft: Double, with player: AVPlayer, for playerName: String) {
        NSLog("## Wait for content to stop playing")
        
        // Adding some extra time to ensure that content finishes
        Thread.sleep(forTimeInterval: timeLeft + 5.0)
        
        let events = getEventsAndReset(for: playerName)
        let containsEndEvent = events?.contains { $0 is MUXSDKEndedEvent } ?? false
        #expect(containsEndEvent)
    }
    
    func assertChangeVideoSource(from firstURL: String, to secondURL: String, with player: AVPlayer, for playerName: String) {
        NSLog("## Change video source from \(firstURL) to \(secondURL)")
        
        // Create CVD for the new video, to use in the videoChange
        let customerVideoData = MUXSDKCustomerVideoData()
        customerVideoData.videoTitle = "Second Video Title"
        customerVideoData.videoId = "second_video_id"
        
        let customerData = MUXSDKCustomerData()
        customerData.customerVideoData = customerVideoData
        
        // Manually trigger video change
        MUXSDKStats.videoChange(forPlayer: playerName, with: customerData)
        
        // Replace current item with new URL
        let newURL = URL(string: secondURL)!
        let newPlayerItem = AVPlayerItem(url: newURL)
        player.replaceCurrentItem(with: newPlayerItem)
        
        Thread.sleep(forTimeInterval: dispatchDelay)
        
        let events = getEventsAndReset(for: playerName)
        
        guard let events = events else {
            Issue.record("No events captured during video source change")
            return
        }
        
        // Find the ViewEnd event index
        let viewEndIndex = events.firstIndex { $0 is MUXSDKViewEndEvent }
        
        // Expect ViewEnd event was sent
        #expect(viewEndIndex != nil, "Expected ViewEnd event when changing video source")
        
        guard let viewEndIndex = viewEndIndex else {
            return
        }
        
        let eventsAfterViewEnd = Array(events[(viewEndIndex + 1)...])
        
        // Find one MUXSDKDataEvent after ViewEnd
        let dataEventAfterViewEnd = eventsAfterViewEnd.first { $0 is MUXSDKDataEvent } as? MUXSDKDataEvent
        
        if let dataEvent = dataEventAfterViewEnd {
            #expect(dataEvent.videoData?.videoSourceUrl != firstURL, "Data event after viewEnd should have a different URL")
        }
    }
    @Test func mockServerDynamicSegmentsTest() async throws {
        let mockServer = MockHLSServer()
        try mockServer.start()
        defer { mockServer.stop() }
        
        print("Server started on: \(mockServer.baseURL)")
        
        // TEST 1: Normal segments
        print("\n📋 TEST 1: Playing normal segments (should work)")
        let playerName1 = "normalSegments \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer { MUXSDKCore.resetCapturedEvents(forPlayer: playerName1) }
        
        let binding1 = MUXSDKPlayerBinding(playerName: playerName1, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let normalURL = mockServer.normalSegmentsURL
        
        let avPlayer1 = AVPlayer(url: URL(string: normalURL)!)
        binding1.attach(avPlayer1)
        
        await MainActor.run {
            avPlayer1.play()
        }
        
        // Wait for segments to be requested
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        let events1 = getEventsAndReset(for: playerName1)
        
        binding1.detachAVPlayer()
        
        // TEST 2: Failing segments
        let playerName2 = "failingSegments \(UUID().uuidString)"
        MUXSDKCore.resetCapturedEvents(forPlayer: playerName2)
        
        let binding2 = MUXSDKPlayerBinding(playerName: playerName2, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let failingURL = mockServer.failingSegmentsURL
        print("🎯 Failing playlist URL: \(failingURL)")
        
        let avPlayer2 = AVPlayer(url: URL(string: failingURL)!)
        binding2.attach(avPlayer2)
        
        await MainActor.run {
            avPlayer2.play()
        }
        
        // Wait for segments to fail
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        let events2 = getEventsAndReset(for: playerName2)
        
                 binding2.detachAVPlayer()
         
         // TEST 3: Proxy functionality
         print("\n📋 TEST 3: Testing proxy functionality")
         let proxyURL = mockServer.proxyURL(path: "VcmKA6aqzIzlg3MayLJDnbF55kX00mds028Z65QxvBYaA.m3u8", host: "stream.mux.com")
         print("🔄 Proxy URL: \(proxyURL)")
         
         let playerName3 = "proxyPlayer \(UUID().uuidString)"
         MUXSDKCore.resetCapturedEvents(forPlayer: playerName3)
         
         let binding3 = MUXSDKPlayerBinding(playerName: playerName3, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
         let avPlayer3 = AVPlayer(url: URL(string: proxyURL)!)
         binding3.attach(avPlayer3)
         
         await MainActor.run {
             avPlayer3.play()
         }
         
         // Wait for proxy request
         try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
         
         let events3 = getEventsAndReset(for: playerName3)
         print("🔄 Proxy - Events captured: \(events3?.count ?? 0)")
         
         binding3.detachAVPlayer()
         
         // Basic assertions
         #expect(events1 != nil, "Expected some events from normal segments")
         #expect(events2 != nil, "Expected some events from failing segments")
         #expect(events3 != nil, "Expected some events from proxy")
    }
    
    
    @Test func vodPlaybackTest() async throws {
        let playerName = "vodPlayer \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let VOD_URL = "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
        let avPlayer = AVPlayer(url: URL(string: VOD_URL)!)
        binding.attach(avPlayer)
        
        // Start playing VoD content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, with: avPlayer, for: playerName)
        
        // Pause the content for 5 seconds
        await assertPauseForNSeconds(n: 5.0, with: avPlayer, for: playerName)
        
        // Unpause the content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, with: avPlayer, for: playerName)
        
        // Seek backwards in the video 5 seconds
        assertSeekNSeconds(n: -5.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, with: avPlayer, for: playerName)
        
        // Seek forwards in the video 10 seconds
        assertSeekNSeconds(n: 10.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, with: avPlayer, for: playerName)
        
        // Exit the player by going back to the menu
        binding.detachAVPlayer()
    }
    
    @Test func livePlaybackTest() async throws {
        let playerName = "livePlayerName \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let LIVE_URL = "https://stream.mux.com/v69RSHhFelSm4701snP22dYz2jICy4E4FUyk02rW4gxRM.m3u8"
        let avPlayer = AVPlayer(url: URL(string: LIVE_URL)!)
        binding.attach(avPlayer)
        
        // Start playing Live content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 10 seconds
        assertWaitForNSeconds(n : 5.0, with: avPlayer, for: playerName)
        
        // Pause the content for 5 seconds
        await assertPauseForNSeconds(n: 5.0, with: avPlayer, for: playerName)
        
        // Unpause the content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, with: avPlayer, for: playerName)
        
        // Seek backwards in the video 5 seconds
        assertSeekNSeconds(n: -5.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, with: avPlayer, for: playerName)
        
        // Seek forwards in the video 5 seconds
        assertSeekNSeconds(n: 5.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, with: avPlayer, for: playerName)
        
        // Exit the player by going back to the menu
        binding.detachAVPlayer()
    }
    
    @Test func playOffMainThreadTest() async throws {
        let playerName = "offMainThreadPlayerName \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        
        let LIVE_URL = "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
        let avPlayer = AVPlayer(url: URL(string: LIVE_URL)!)
        let playerViewController = await MainActor.run {
            AVPlayerViewController()
        }
        var binding: MockAVPlayerViewControllerBinding!
        
        binding = MockAVPlayerViewControllerBinding(
            playerName: playerName,
            softwareName: "TestSoftwareName",
            softwareVersion: "TestSoftwareVersion",
            playerViewController: playerViewController
        )
        binding.attach(avPlayer)
        
        // Call play in background thread
        DispatchQueue.global(qos: .background).async {
            let isMain = Thread.isMainThread
            let isMultiThreaded = Thread.isMultiThreaded()
            #expect(isMultiThreaded, "Expected this code to run multi threaded")
            #expect(!isMain, "Expected this code to run off the main thread")
            
            avPlayer.play()
        }
        
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds in nanoseconds
        #expect(binding.didReturnNil, "Expected getViewBounds to return empty CGRect")
    }
    
    @Test func vodEndingTest() async throws {
        let playerName = "vodEndingPlayerName \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let VOD_URL = "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
        let avPlayer = AVPlayer(url: URL(string: VOD_URL)!)
        binding.attach(avPlayer)
        
        // Start playing content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n: 5.0, with: avPlayer, for: playerName)
        
        let vodDurationSeconds = await MainActor.run { () -> Double in
            let duration = avPlayer.currentItem?.asset.duration
            return CMTimeGetSeconds(duration!)
        }
        
        // Seek to approximately 10 seconds before the end of the content
        let seekTime = CMTime(seconds: vodDurationSeconds - 10.0, preferredTimescale: 1000)
        await avPlayer.seek(to: seekTime)
        
        // Assert that content has ended
        assertFinishPlaying(timeLeft: 10.0, with: avPlayer, for: playerName)
    }
    
    @Test func changingSourceTest() async throws {
        let playerName = "changingSourcePlayer \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let FIRST_VIDEO_URL = "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
        let SECOND_VIDEO_URL = "https://stream.mux.com/v69RSHhFelSm4701snP22dYz2jICy4E4FUyk02rW4gxRM.m3u8"
        let avPlayer = AVPlayer(url: URL(string: FIRST_VIDEO_URL)!)
        binding.attach(avPlayer)
        
        // Begin playback of first content title
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait 5 seconds
        assertWaitForNSeconds(n: 5.0, with: avPlayer, for: playerName)
        
        // Select a different content title
        assertChangeVideoSource(from: FIRST_VIDEO_URL, to: SECOND_VIDEO_URL, with: avPlayer, for: playerName)
        
        // Start playing the new content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait 5 seconds
        assertWaitForNSeconds(n: 5.0, with: avPlayer, for: playerName)
        
        binding.detachAVPlayer()
    }
    
    @Test func fatalErrorTest() async throws {
        let playerName = "fatalErrorPlayer \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        
        // Use an invalid URL
        let INVALID_URL = "https://bitdash-a.akamaihd.net/content/nonexistent/invalid.m3u8"
        let avPlayer = AVPlayer(url: URL(string: INVALID_URL)!)
        binding.attach(avPlayer)
        
        // Try to play the invalid content which should trigger a fatal error
        await MainActor.run {
            avPlayer.play()
        }
        
        // Wait for error to occur and be processed
        try? await Task.sleep(nanoseconds: UInt64(dispatchDelay * 2 * 1_000_000_000))
        
        let events = getEventsAndReset(for: playerName)
        
        // Check for MUXSDKErrorEvent
        let errorEvents = events?.compactMap { $0 as? MUXSDKErrorEvent } ?? []
        let hasErrorEvents = !errorEvents.isEmpty
        #expect(hasErrorEvents, "Expected MUXSDKErrorEvent to be captured for fatal error")
        
        // Verify error event properties
        var hasFatalError = false
        var hasErrorCode = false
        var hasErrorMessage = false
        
        for errorEvent in errorEvents {
            if let playerData = errorEvent.playerData {
                if let errorCode = playerData.playerErrorCode, !errorCode.isEmpty {
                    hasErrorCode = true
                    
                }
                
                if let errorMessage = playerData.playerErrorMessage, !errorMessage.isEmpty {
                    hasErrorMessage = true
                }
            }
            
            // Check if this is a fatal error (we expect fatal errors for playback failures)
            if errorEvent.severity == MUXSDKErrorSeverity.fatal {
                hasFatalError = true
            }
        }
        
        // Verify that error information is captured
        #expect(hasErrorCode, "Expected error code to be captured in fatal error event")
        #expect(hasErrorMessage, "Expected error message to be captured in fatal error event")
        #expect(hasFatalError, "Expected the error to be fatal")
        
        // Exit
        binding.detachAVPlayer()
    }
    
    @Test func watchTimeTest() async throws {
        let playerName = "watchTimePlayer \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let VOD_URL = "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
        let avPlayer = AVPlayer(url: URL(string: VOD_URL)!)
        binding.attach(avPlayer)
        
        // Start playing content
        await MainActor.run {
            avPlayer.play()
        }
        
        let watchTimeStart = getLastTimestamp(for: playerName)?.doubleValue
        
        // Play for 20 seconds straight
        try? await Task.sleep(nanoseconds: UInt64(20 * 1_000_000_000))
        
        // End the view
        let watchTimeEnd = getLastTimestamp(for: playerName)!.doubleValue
        binding.detachAVPlayer()
        
        // Calculate actual watch time
        let actualWatchTimeMs = watchTimeEnd - (watchTimeStart ?? 0)
        let actualWatchTimeSeconds = actualWatchTimeMs / 1000.0
        
        // The expected watching time should be approximately 20 seconds
        let expectedPlaybackTime = 20.0
        let tolerance = 2.0 // Allow 2 second tolerance
        
        #expect(
            actualWatchTimeSeconds >= expectedPlaybackTime - tolerance &&
            actualWatchTimeSeconds <= expectedPlaybackTime + tolerance,
            "Watch time should be approximately \(expectedPlaybackTime) seconds (±\(tolerance)s), but was \(actualWatchTimeSeconds) seconds"
        )
    }
}
