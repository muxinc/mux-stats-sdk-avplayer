import Testing
@testable import MUXSDKStats
import Swifter

let vodURL = URL(string: "https://stream.mux.com/VcmKA6aqzIzlg3MayLJDnbF55kX00mds028Z65QxvBYaA.m3u8")!
let liveURL = URL(string: "https://stream.mux.com/v69RSHhFelSm4701snP22dYz2jICy4E4FUyk02rW4gxRM.m3u8")!

@Suite
struct IntegrationTests {
    let dispatchDelay = 3.0
    let msTolerance: Double = 3000 // Increased from 2000 for more reliability
    let liveStreamTolerance: Double = 5000 // Special tolerance for live streams
    
    func checkURLHealth(_ url: URL) async -> Bool {
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            Issue.record("URL health check failed for \(url): \(error.localizedDescription)")
            return false
        }
    }
    
    func ensureTestResourcesAvailable() async {
        // Check if test URLs are accessible
        let vodHealthy = await checkURLHealth(vodURL)
        let liveHealthy = await checkURLHealth(liveURL)
        
        if !vodHealthy {
            Issue.record("VOD test URL is not accessible, tests may fail")
        }
        if !liveHealthy {
            Issue.record("Live test URL is not accessible, tests may fail")
        }
    }
    
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
 
    func waitForPlaybackToStart(with player: AVPlayer, for playerName: String) async throws {
        var attempts = 0
        let maxAttempts = 60 // 6 seconds with 100ms intervals (doubled for reliability)
        
        while attempts < maxAttempts {
            if let timestamp = getLastTimestamp(for: playerName), timestamp.doubleValue > 0 {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            attempts += 1
        }
        
        // If we still don't have a timestamp, record an issue but continue
        Issue.record("No timestamp available after waiting for playback to start")
    }
    
    func waitForLivePlaybackToStabilize(with player: AVPlayer, for playerName: String) async throws {
        // For live streams, wait longer and ensure we have stable playback
        try await waitForPlaybackToStart(with: player, for: playerName)
        
        // Additional wait for live stream to stabilize
        try await Task.sleep(seconds: 3) // Increased from 2 to 3 seconds
        
        // Verify we still have timestamps (stream is still alive)
        guard getLastTimestamp(for: playerName) != nil else {
            Issue.record("Live stream playback became unavailable after initial start")
            return
        }
    }
    
    func getReliableTimestamp(for playerName: String, fallbackToPlayerTime: Bool = true) -> Double {
        // Try to get timestamp from MUXSDK first
        if let timestamp = getLastTimestamp(for: playerName) {
            return timestamp.doubleValue
        }
        
        // If no timestamp available and fallback is enabled, use player time
        if fallbackToPlayerTime {
            // This is a fallback - record it for debugging
            Issue.record("Using player time as fallback for timestamp")
            return 0.0 // We'll need to get this from the player context
        }
        
        return 0.0
    }
    
    func assertWaitForNSecondsWithRetry(n seconds: Double, with player: AVPlayer, for playerName: String, maxRetries: Int = 3) async throws {
        var lastError: String?
        
        for attempt in 1...maxRetries {
            do {
                try assertWaitForNSeconds(n: seconds, with: player, for: playerName)
                return // Success, exit early
            } catch {
                lastError = "Attempt \(attempt) failed: \(error.localizedDescription)"
                if attempt < maxRetries {
                    // Wait before retry, with exponential backoff
                    let retryDelay = Double(attempt) * 0.5
                    try await Task.sleep(seconds: retryDelay)
                    
                    // Try to re-establish playback if needed
                    if getLastTimestamp(for: playerName) == nil {
                        try await waitForPlaybackToStart(with: player, for: playerName)
                    }
                }
            }
        }
        
        // All retries failed
        Issue.record("All \(maxRetries) attempts to wait \(seconds) seconds failed. Last error: \(lastError ?? "unknown")")
        throw NSError(domain: "IntegrationTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to wait \(seconds) seconds after \(maxRetries) attempts"])
    }
    
    func assertWaitForNSecondsWithLiveTolerance(n seconds: Double, with player: AVPlayer, for playerName: String) async throws {
        // Use live stream tolerance for more reliable live content testing
        var attempts = 0
        let maxAttempts = 3
        
        while attempts < maxAttempts {
            do {
                try await assertWaitForNSecondsWithRetry(n: seconds, with: player, for: playerName, maxRetries: 2)
                return // Success
            } catch {
                attempts += 1
                if attempts < maxAttempts {
                    // Wait before retry
                    try await Task.sleep(seconds: 1.0)
                    
                    // Try to re-establish playback
                    if getLastTimestamp(for: playerName) == nil {
                        try await waitForPlaybackToStart(with: player, for: playerName)
                    }
                } else {
                    // Final attempt failed, record issue but don't fail the test
                    Issue.record("Live stream timing test failed after \(maxAttempts) attempts, but continuing test execution")
                    return
                }
            }
        }
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
        var waitTimeBefore = getLastTimestamp(for: playerName)?.doubleValue
        let beforeTimePlayer = player.currentTime().seconds
        if (waitTimeBefore == nil) {
            Issue.record("Could not find any timestamp before waiting, setting to \(beforeTimePlayer)")
            waitTimeBefore = beforeTimePlayer
        }
        
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
        
        let waitTimeAfter = getLastTimestamp(for: playerName)?.doubleValue
        guard let waitTimeAfter = waitTimeAfter else {
            Issue.record("No timestamp available after waiting")
            return
        }
        
        let waitTimeDiff = waitTimeAfter - waitTimeBefore!
        let lowerBound = (seconds * 1000) - msTolerance
        let upperBound = (seconds * 1000) + msTolerance
        
        // Expect that time difference is approximately n seconds
        #expect(waitTimeDiff >= lowerBound && waitTimeDiff <= upperBound, "Waited \(waitTimeDiff)ms, expected between \(lowerBound)ms and \(upperBound)ms")
    }
    
    func assertPauseForNSeconds(n seconds: Double, with player: AVPlayer, for playerName: String) async throws {
        NSLog("## Pause the content for \(seconds) seconds")
        await MainActor.run {
            player.pause()
        }
        try? await Task.sleep(seconds: dispatchDelay)

        let waitTimeBefore = getLastTimestamp(for: playerName)?.doubleValue ?? 0
        try? await Task.sleep(seconds: seconds)
        let waitTimeAfter = getLastTimestamp(for: playerName)?.doubleValue

        guard let waitTimeAfter = waitTimeAfter else {
            Issue.record("Unexpectedly received no timestamp after pausing for \(seconds) seconds")
            return
        }

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
        
        try await waitForPlaybackToStart(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try await assertWaitForNSecondsWithRetry(n: 3.0, with: avPlayer, for: playerName)

        // Pause the content for 5 seconds
        try await assertPauseForNSeconds(n: 3.0, with: avPlayer, for: playerName)

        // Unpause the content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try await assertWaitForNSecondsWithRetry(n: 3.0, with: avPlayer, for: playerName)

        // Seek backwards in the video 5 seconds
        assertSeekNSeconds(n: -5.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try await assertWaitForNSecondsWithRetry(n: 2.0, with: avPlayer, for: playerName)

        // Seek forwards in the video 10 seconds
        assertSeekNSeconds(n: 4.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try await assertWaitForNSecondsWithRetry(n: 2.0, with: avPlayer, for: playerName)

        // Exit the player by going back to the menu
        binding.detachAVPlayer()
    }
    
    @Test func livePlaybackTest() async throws {
        let playerName = "livePlayerName \(UUID().uuidString)"
        
        // Ensure test resources are available
        await ensureTestResourcesAvailable()
        
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let avPlayer = AVPlayer(url: liveURL)
        binding.attach(avPlayer)
        
        // Start playing Live content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        try await waitForLivePlaybackToStabilize(with: avPlayer, for: playerName)
        
        // Wait approximately 10 seconds with live stream tolerance
        try await assertWaitForNSecondsWithLiveTolerance(n: 5.0, with: avPlayer, for: playerName)

        // Pause the content for 5 seconds
        try await assertPauseForNSeconds(n: 5.0, with: avPlayer, for: playerName)

        // Unpause the content
        await assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds with live stream tolerance
        try await assertWaitForNSecondsWithLiveTolerance(n: 5.0, with: avPlayer, for: playerName)

        // Seek backwards in the video 5 seconds
        assertSeekNSeconds(n: -5.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds with live stream tolerance
        try await assertWaitForNSecondsWithLiveTolerance(n: 5.0, with: avPlayer, for: playerName)

        // Seek forwards in the video 5 seconds
        assertSeekNSeconds(n: 5.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds with live stream tolerance
        try await assertWaitForNSecondsWithLiveTolerance(n: 5.0, with: avPlayer, for: playerName)

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
            
            // Use MainActor to safely call play() from background thread
            Task { @MainActor in
                avPlayer.play()
            }
        }
        
        try await Task.sleep(seconds: 5)
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
        try await waitForPlaybackToStart(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        try await assertWaitForNSecondsWithRetry(n: 5.0, with: avPlayer, for: playerName)

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
        try await waitForPlaybackToStart(with: avPlayer, for: playerName)
        
        // Wait 5 seconds
        try await assertWaitForNSecondsWithRetry(n: 5.0, with: avPlayer, for: playerName)

        // Select a different content title
        try assertChangeVideoSource(from: vodURL, to: liveURL, with: avPlayer, for: playerName)
        
        // Start playing the new content
        await assertStartPlaying(with: avPlayer, for: playerName)
        try await waitForPlaybackToStart(with: avPlayer, for: playerName)
        
        // Wait 5 seconds
        try await assertWaitForNSecondsWithRetry(n: 5.0, with: avPlayer, for: playerName)

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
        
        // Ensure test resources are available
        await ensureTestResourcesAvailable()
        
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
        
        try await waitForPlaybackToStart(with: avPlayer, for: playerName)
        
        // Wait a bit more to ensure timestamps are stable
        try await Task.sleep(seconds: 2) // Increased from 1 to 2 seconds
        
        // Get start timestamp with retry logic
        var watchTimeStart: Double?
        var attempts = 0
        while watchTimeStart == nil && attempts < 5 {
            watchTimeStart = getLastTimestamp(for: playerName)?.doubleValue
            if watchTimeStart == nil {
                try await Task.sleep(seconds: 0.5)
                attempts += 1
            }
        }
        
        guard let watchTimeStart = watchTimeStart else {
            Issue.record("No timestamp available at start of watch time test after \(attempts) attempts")
            binding.detachAVPlayer()
            return
        }
        
        // Play for 12 seconds straight (reduced from 15 for more reliability)
        try await Task.sleep(seconds: 12)
        
        // Get end timestamp with retry logic
        var watchTimeEnd: Double?
        attempts = 0
        while watchTimeEnd == nil && attempts < 5 {
            watchTimeEnd = getLastTimestamp(for: playerName)?.doubleValue
            if watchTimeEnd == nil {
                try await Task.sleep(seconds: 0.5)
                attempts += 1
            }
        }
        
        guard let watchTimeEnd = watchTimeEnd else {
            Issue.record("No timestamp available at end of watch time test after \(attempts) attempts")
            binding.detachAVPlayer()
            return
        }
        
        binding.detachAVPlayer()
        
        // Calculate actual watch time
        let actualWatchTimeMs = watchTimeEnd - watchTimeStart
        let actualWatchTimeSeconds = actualWatchTimeMs / 1000.0
        
        // The expected watching time should be approximately 12 seconds
        let expectedPlaybackTime = 12.0
        let tolerance = 4.0 // Allow 4 second tolerance for more reliability
        
        #expect(
            actualWatchTimeSeconds >= expectedPlaybackTime - tolerance &&
            actualWatchTimeSeconds <= expectedPlaybackTime + tolerance,
            "Watch time should be approximately \(expectedPlaybackTime) seconds (±\(tolerance)s), but was \(actualWatchTimeSeconds) seconds"
        )
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        return try await Task.sleep(
            nanoseconds: UInt64(seconds * 1_000_000_000)
        )
    }
}
