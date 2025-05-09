import Testing
@testable import MUXSDKStats

@Suite
struct IntegrationTests {
    let playerName = "TestPlayerName"
    let dispatchDelay = 1.0
    
    @Test func createBinding() throws {
        let binding = MUXSDKPlayerBinding(playerName: "TestPlayerName", softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        _ = binding
    }
    
    func getLatestTimeUpdateEvent(for playerName: String) -> NSNumber? {
        let events = MUXSDKCore.getEventsForPlayer(playerName)
        return events?
            .compactMap { $0 as? MUXSDKTimeUpdateEvent }
            .last?
            .playerData?
            .playerPlayheadTime
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
        let waitTimeBefore = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        Thread.sleep(forTimeInterval: TimeInterval(seconds))
        let waitTimeAfter = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        let waitTimeDiff = waitTimeAfter - waitTimeBefore
        let lowerBound = (seconds * 1000) - 1000
        let upperBound = (seconds * 1000) + 1000
        
        // Expect that time difference is approximately n seconds
        #expect(waitTimeDiff >= lowerBound && waitTimeDiff <= upperBound)
    }
    
    func assertPauseForNSeconds(n seconds: Double, with player: AVPlayer) {
        NSLog("## Pause the content for \(seconds) seconds")
        let waitTimeBefore = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        player.pause()
        Thread.sleep(forTimeInterval: TimeInterval(seconds))
        
        let waitTimeAfter = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        let waitTimeDiff = waitTimeAfter - waitTimeBefore
        // Expect that time difference is approximately 0 seconds
        #expect(waitTimeDiff >= 0 && waitTimeDiff < 1000)
        
        var events = getEventsAndReset(for: playerName)
        let containsPauseEvent = events?.contains { $0 is MUXSDKPauseEvent } ?? false
        // Expect that MUXSDKPauseEvent was sent
        #expect(containsPauseEvent)
        Thread.sleep(forTimeInterval: dispatchDelay)
    }
    
    func assertUnpause(with player: AVPlayer) {
        NSLog("## Unpause the content")
        player.play()
        Thread.sleep(forTimeInterval: dispatchDelay)
        let events = getEventsAndReset(for: playerName)
        let containsPlayEvent = events?.contains { $0 is MUXSDKPlayEvent } ?? false
        
        // Expect that MUXSDKPlayEvent was sent
        #expect(containsPlayEvent)
        Thread.sleep(forTimeInterval: dispatchDelay)
    }
    
    func assertSeekBackwardsNSeconds(n seconds: Double, with player: AVPlayer) {
        NSLog("## Seek back \(seconds) seconds")
        let currentTimeBack = player.currentTime()
        let seekTimeBack = CMTime(seconds: currentTimeBack.seconds - seconds, preferredTimescale: 1)
        var seekTimeBefore = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        player.seek(to: seekTimeBack)
        Thread.sleep(forTimeInterval: 0.5)
        
        var seekTimeAfter = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        var seekTimeDiff = seekTimeAfter - seekTimeBefore
        let lowerBound = (-seconds * 1000) + 1000
        let upperBound = (-seconds * 1000) - 1000
        
        // Expect that time has gone backwards approximately n seconds
        #expect(seekTimeDiff <= lowerBound && seekTimeDiff >= upperBound)
        Thread.sleep(forTimeInterval: dispatchDelay)
    }
    
    func assertSeekForwardsNSeconds(n seconds: Double, with player: AVPlayer) {
        NSLog("## Seek forwards \(seconds) seconds")
        let currentTimeForwards = player.currentTime()
        let seekTimeForwards = CMTime(seconds: currentTimeForwards.seconds + seconds, preferredTimescale: 1)
        let seekTimeBefore = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        player.seek(to: seekTimeForwards)
        Thread.sleep(forTimeInterval: 0.5)
        let seekTimeAfter = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        let seekTimeDiff = seekTimeAfter - seekTimeBefore
        let lowerBound = (seconds * 1000) - 1000
        let upperBound = (seconds * 1000) + 1000
        
        // Expect that time has gone forwards n seconds
        #expect(seekTimeDiff >= lowerBound && seekTimeDiff <= upperBound)
        Thread.sleep(forTimeInterval: dispatchDelay)
        
        let events = getEventsAndReset(for: playerName)
        let containsSeekEvent = events?.contains { $0 is MUXSDKSeekedEvent } ?? false
        
        // Expect that MUXSDKSeekEvent was sent
        #expect(containsSeekEvent)
        Thread.sleep(forTimeInterval: dispatchDelay)
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
        assertUnpause(with: avPlayer)
        
        // Wait approximately 30 seconds
        assertWaitForNSeconds(n : 30.0)
        
        // Seek backwards in the video 10 seconds
        assertSeekBackwardsNSeconds(n: 10.0, with: avPlayer)
        
        // Wait approximately 30 seconds
        assertWaitForNSeconds(n : 30.0)
        
        // Seek forwards in the video
        assertSeekForwardsNSeconds(n: 20.0, with: avPlayer)
        
        // Wait approximately 30 seconds
        assertWaitForNSeconds(n : 30.0)
        
        // Exit the player by going back to the menu
        // TBD: How to do this
    }
}
