import Testing
@testable import MUXSDKStats

@Suite
struct IntegrationTests {
    let playerName = "TestPlayerName"
    let dispatchDelay = 1.0
    let msTolerance: Double = 2000
    
    func getLastTimestamp(for playerName: String) -> NSNumber? {
        guard let timeStamps = MUXSDKCore.getTimeStamps(forPlayer: playerName) as? [NSNumber] else {
            return nil
        }
        return timeStamps.last
    }
    
    func getTimeDeltas(for playerName: String) -> [NSNumber] {
        guard let timeDeltas = MUXSDKCore.getTimeDeltas(forPlayer: playerName) as? [NSNumber] else {
            return []
        }
        return timeDeltas
    }
    
    func getEventsAndReset(for playerName: String) -> [MUXSDKBaseEvent]? {
        let events = MUXSDKCore.getEventsForPlayer(playerName)
        MUXSDKCore.resetCapturedEvents()
        return events
    }
    
    func assertStartPlaying(with player: AVPlayer) {
        NSLog("## Start playing content")
        player.play()
        Thread.sleep(forTimeInterval: dispatchDelay)

        let events = getEventsAndReset(for: playerName)
        let containsPlayEvent = events?.contains { $0 is MUXSDKPlayEvent } ?? false
        
        // Expect that MUXSDKPlayEvent was sent
        #expect(containsPlayEvent)
        Thread.sleep(forTimeInterval: dispatchDelay)
    }
    
    func assertWaitForNSeconds(n seconds: Double){
        NSLog("## Wait approximately \(seconds) seconds")
        let waitTimeBefore = getLastTimestamp(for: playerName)!.doubleValue
        Thread.sleep(forTimeInterval: TimeInterval(seconds))
        let waitTimeAfter = getLastTimestamp(for: playerName)!.doubleValue
        let waitTimeDiff = waitTimeAfter - waitTimeBefore
        let lowerBound = (seconds * 1000) - msTolerance
        let upperBound = (seconds * 1000) + msTolerance
        
        // Expect that time difference is approximately n seconds
        #expect(waitTimeDiff >= lowerBound && waitTimeDiff <= upperBound, "Waited \(waitTimeDiff)ms, expected between \(lowerBound)ms and \(upperBound)ms")
    }
    
    func assertPauseForNSeconds(n seconds: Double, with player: AVPlayer) {
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
        Thread.sleep(forTimeInterval: dispatchDelay)
    }
    
    func assertSeekNSeconds(n seconds: Double, with player: AVPlayer) {
        NSLog("## Seek \(seconds) seconds")
        let currentTime = player.currentTime()
        let seekTime = CMTime(seconds: currentTime.seconds + seconds, preferredTimescale: 1)
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
        MUXSDKCore.swizzleDispatchEvents()
        MUXSDKCore.resetCapturedEvents()
        
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let VOD_URL = "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
        let avPlayer = AVPlayer(url: URL(string: VOD_URL)!)
        binding.attach(avPlayer)
                
        // Start playing VoD content
        assertStartPlaying(with: avPlayer)
                
        // Wait approximately 30 seconds
        assertWaitForNSeconds(n : 30.0)
        
        // Pause the content for 5 seconds
        assertPauseForNSeconds(n: 5.0, with: avPlayer)
        
        // Unpause the content
        assertStartPlaying(with: avPlayer)
        
        // Wait approximately 30 seconds
        assertWaitForNSeconds(n : 30.0)
        
        // Seek backwards in the video 10 seconds
        assertSeekNSeconds(n: -10.0, with: avPlayer)
        
        // Wait approximately 30 seconds
        assertWaitForNSeconds(n : 30.0)
        
        // Seek forwards in the video 20 seconds
        assertSeekNSeconds(n: 20.0, with: avPlayer)
        
        // Wait approximately 30 seconds
        assertWaitForNSeconds(n : 30.0)
        
        // Exit the player by going back to the menu
        binding.detachAVPlayer()
    }
}
