import Testing
@testable import MUXSDKStats

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
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        return MUXSDKCore.getEventsForPlayer(playerName)
    }
    
    func assertStartPlaying(with player: AVPlayer, for playerName: String) {
        NSLog("## Start playing content")
        player.play()
        Thread.sleep(forTimeInterval: dispatchDelay)

        let events = getEventsAndReset(for: playerName)
        
        let containsPlayEvent = events?.contains { $0 is MUXSDKPlayEvent } ?? false
        
        // Expect that MUXSDKPlayEvent was sent
        #expect(containsPlayEvent)
    }
    
    func assertWaitForNSeconds(n seconds: Double, for playerName: String, with player: AVPlayer){
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
    
    func assertPauseForNSeconds(n seconds: Double, with player: AVPlayer, for playerName: String) {
        NSLog("## Pause the content for \(seconds) seconds")
        let waitTimeBefore = getLastTimestamp(for: playerName)!.doubleValue
        player.pause()
        Thread.sleep(forTimeInterval: TimeInterval(seconds))
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
    
    @Test func vodPlaybackTest() throws {
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
        assertStartPlaying(with: avPlayer, for: playerName)
                
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, for: playerName, with: avPlayer)
        
        // Pause the content for 5 seconds
        assertPauseForNSeconds(n: 5.0, with: avPlayer, for: playerName)
        
        // Unpause the content
        assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, for: playerName, with: avPlayer)
        
        // Seek backwards in the video 5 seconds
        assertSeekNSeconds(n: -5.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, for: playerName, with: avPlayer)
        
        // Seek forwards in the video 10 seconds
        assertSeekNSeconds(n: 10.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, for: playerName, with: avPlayer)
        
        // Exit the player by going back to the menu
        binding.detachAVPlayer()
    }
    
    @Test func livePlaybackTest() throws {
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
        assertStartPlaying(with: avPlayer, for: playerName)
                
        // Wait approximately 10 seconds
        assertWaitForNSeconds(n : 5.0, for: playerName, with: avPlayer)
        
        // Pause the content for 5 seconds
        assertPauseForNSeconds(n: 5.0, with: avPlayer, for: playerName)
        
        // Unpause the content
        assertStartPlaying(with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, for: playerName, with: avPlayer)
        
        // Seek backwards in the video 5 seconds
        assertSeekNSeconds(n: -5.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, for: playerName, with: avPlayer)
        
        // Seek forwards in the video 5 seconds
        assertSeekNSeconds(n: 5.0, with: avPlayer, for: playerName)
        
        // Wait approximately 5 seconds
        assertWaitForNSeconds(n : 5.0, for: playerName, with: avPlayer)
        
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
}
