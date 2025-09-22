import Testing
@testable import MUXSDKStats

let vodURL = URL(string: "https://stream.mux.com/a4nOgmxGWg6gULfcBbAa00gXyfcwPnAFldF8RdsNyk8M.m3u8")!
let liveURL = URL(string: "https://stream.mux.com/v69RSHhFelSm4701snP22dYz2jICy4E4FUyk02rW4gxRM.m3u8")!

@Suite(.serialized)
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
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
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
    
    func assertWaitForNSeconds(n seconds: Double, with player: AVPlayer, for playerName: String) throws {
        NSLog("## Wait approximately \(seconds) seconds")
        let waitTimeBefore = try #require(getLastTimestamp(for: playerName)).doubleValue
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
        
        let waitTimeAfter = try #require(getLastTimestamp(for: playerName)).doubleValue
        let waitTimeDiff = waitTimeAfter - waitTimeBefore
        let lowerBound = (seconds * 1000) - msTolerance
        let upperBound = (seconds * 1000) + msTolerance
        
        // Expect that time difference is approximately n seconds
        #expect(waitTimeDiff >= lowerBound && waitTimeDiff <= upperBound, "Waited \(waitTimeDiff)ms, expected between \(lowerBound)ms and \(upperBound)ms")
    }
    
    func assertPauseForNSeconds(n seconds: Double, with player: AVPlayer, for playerName: String) async throws {
        NSLog("## Pause the content for \(seconds) seconds")
        let waitTimeBefore = try #require(getLastTimestamp(for: playerName)).doubleValue
        await MainActor.run {
            player.pause()
        }
        try? await Task.sleep(nanoseconds: UInt64(dispatchDelay * 1_000_000_000))
        let waitTimeAfter = try #require(getLastTimestamp(for: playerName)).doubleValue

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
    
    func assertChangeVideoSource(from firstURL: URL, to secondURL: URL, with player: AVPlayer, for playerName: String) throws {
        
        // Create CVD for the new video, to use in the videoChange
        let customerVideoData = MUXSDKCustomerVideoData()
        customerVideoData.videoTitle = "Second Video Title"
        customerVideoData.videoId = "second_video_id"
        
        let customerData = MUXSDKCustomerData()
        customerData.customerVideoData = customerVideoData
        
        // Manually trigger video change
        MUXSDKStats.videoChange(forPlayer: playerName, with: customerData)
        
        // Replace current item with new URL
        let newPlayerItem = AVPlayerItem(url: secondURL)
        player.replaceCurrentItem(with: newPlayerItem)
        
        Thread.sleep(forTimeInterval: dispatchDelay)
        
        let events = try #require(getEventsAndReset(for: playerName))
        
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
            #expect(dataEvent.videoData?.videoSourceUrl != firstURL.absoluteString, "Data event after viewEnd should have a different URL")
        }
    }
    
    @Test func vodPlaybackTest() async throws {
        let playerName = "vodPlayer \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let avPlayer = AVPlayer(url: vodURL)
        binding.attach(avPlayer)
        
        // Start playing VoD content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try assertWaitForNSeconds(n : 3.0, with: avPlayer, for: playerName)

        // Pause the content for 5 seconds
        try await assertPauseForNSeconds(n: 3.0, with: avPlayer, for: playerName)

        // Unpause the content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try assertWaitForNSeconds(n : 3.0, with: avPlayer, for: playerName)

        // Seek backwards in the video 5 seconds
        assertSeekNSeconds(n: -5.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try assertWaitForNSeconds(n : 2.0, with: avPlayer, for: playerName)

        // Seek forwards in the video 10 seconds
        assertSeekNSeconds(n: 4.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try assertWaitForNSeconds(n : 2.0, with: avPlayer, for: playerName)

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
        try assertWaitForNSeconds(n : 5.0, with: avPlayer, for: playerName)

        // Pause the content for 5 seconds
        try await assertPauseForNSeconds(n: 5.0, with: avPlayer, for: playerName)

        // Unpause the content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try assertWaitForNSeconds(n : 5.0, with: avPlayer, for: playerName)

        // Seek backwards in the video 5 seconds
        assertSeekNSeconds(n: -5.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try assertWaitForNSeconds(n : 5.0, with: avPlayer, for: playerName)

        // Seek forwards in the video 5 seconds
        assertSeekNSeconds(n: 5.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try assertWaitForNSeconds(n : 5.0, with: avPlayer, for: playerName)

        // Exit the player by going back to the menu
        binding.detachAVPlayer()
    }
    
    @Test func playOffMainThreadTest() async throws {
        let playerName = "offMainThreadPlayerName \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        
        let avPlayer = AVPlayer(url: liveURL)
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
        let avPlayer = AVPlayer(url: vodURL)
        binding.attach(avPlayer)
        
        // Start playing content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try assertWaitForNSeconds(n: 5.0, with: avPlayer, for: playerName)

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
        
        let avPlayer = AVPlayer(url: vodURL)
        binding.attach(avPlayer)
        
        // Begin playback of first content title
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait 5 seconds
        try assertWaitForNSeconds(n: 5.0, with: avPlayer, for: playerName)

        // Select a different content title
        try assertChangeVideoSource(from: vodURL, to: liveURL, with: avPlayer, for: playerName)
        
        // Start playing the new content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait 5 seconds
        try assertWaitForNSeconds(n: 5.0, with: avPlayer, for: playerName)

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
        let notFoundURL = URL(string: "https://stream.mux.com/invalid.m3u8")!
        let avPlayer = AVPlayer(url: notFoundURL)
        binding.attach(avPlayer)
        
        // Try to play the invalid content which should trigger a fatal error
        await MainActor.run {
            avPlayer.play()
        }
        
        // Wait for error to occur and be processed
        try? await Task.sleep(nanoseconds: UInt64(dispatchDelay * 2 * 1_000_000_000))
        
        let events = try #require(getEventsAndReset(for: playerName))
        
        // Check for MUXSDKErrorEvent 
        let errorEvents = events.compactMap { $0 as? MUXSDKErrorEvent }
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
        let avPlayer = AVPlayer(url: vodURL)
        binding.attach(avPlayer)
        
        // Start playing content
        await MainActor.run {
            avPlayer.play()
        }
    
        let watchTimeStart = getLastTimestamp(for: playerName)?.doubleValue
        
        // Play for 20 seconds straight
        try? await Task.sleep(nanoseconds: UInt64(20 * 1_000_000_000))
        
        // End the view
        let watchTimeEnd = try #require(getLastTimestamp(for: playerName)).doubleValue
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
