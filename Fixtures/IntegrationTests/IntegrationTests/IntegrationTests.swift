import Testing
@testable import MUXSDKStats

@Suite
struct IntegrationTests {
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
    
    @Test func vodPlaybackTest() throws {
        MUXSDKCore.swizzleDispatchEvents()
        MUXSDKCore.resetCapturedEvents()
        
        let playerName = "TestPlayerName"
        let dispatchDelay = 1.0
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let VOD_URL = "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
        let avPlayer = AVPlayer(url: URL(string: VOD_URL)!)
        binding.attach(avPlayer)
                
        // Start playing VoD content
        NSLog("## Start playing VoD content")
        avPlayer.play()
        Thread.sleep(forTimeInterval: dispatchDelay)
        var events = getEventsAndReset(for: playerName)
        var containsPlayEvent = events?.contains { $0 is MUXSDKPlayEvent } ?? false
        // Expect that MUXSDKPlayEvent was sent
        #expect(containsPlayEvent)
        Thread.sleep(forTimeInterval: dispatchDelay)
                
        // Wait approximately 30 seconds
        NSLog("## Wait approximately 30 seconds")
        var waitTimeBefore = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        Thread.sleep(forTimeInterval: 30.0)
        var waitTimeAfter = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        var waitTimeDiff = waitTimeAfter - waitTimeBefore
        // Expect that time difference is approximately 30 seconds
        #expect(waitTimeDiff >= 29000 && waitTimeDiff <= 31000)
        
        // Pause the content for 5 seconds
        NSLog("## Pause the content for 5 seconds")
        waitTimeBefore = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        avPlayer.pause()
        Thread.sleep(forTimeInterval: 5.0)
        waitTimeAfter = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        waitTimeDiff = waitTimeAfter - waitTimeBefore
        // Expect that time difference is approximately 0 seconds
        #expect(waitTimeDiff >= 0 && waitTimeDiff < 1000)
        events = getEventsAndReset(for: playerName)
        let containsPauseEvent = events?.contains { $0 is MUXSDKPauseEvent } ?? false
        // Expect that MUXSDKPauseEvent was sent
        #expect(containsPauseEvent)
        Thread.sleep(forTimeInterval: dispatchDelay)
        
        // Unpause the content
        NSLog("## Unpause the content")
        avPlayer.play()
        Thread.sleep(forTimeInterval: dispatchDelay)
        events = getEventsAndReset(for: playerName)
        containsPlayEvent = events?.contains { $0 is MUXSDKPlayEvent } ?? false
        // Expect that MUXSDKPlayEvent was sent
        #expect(containsPlayEvent)
        Thread.sleep(forTimeInterval: dispatchDelay)
        
        // Wait approximately 30 seconds
        NSLog("## Wait approximately 30 seconds")
        waitTimeBefore = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        Thread.sleep(forTimeInterval: 30.0)
        waitTimeAfter = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        waitTimeDiff = waitTimeAfter - waitTimeBefore
        // Expect that time difference is approximately 30 seconds
        #expect(waitTimeDiff >= 29000 && waitTimeDiff <= 31000)
        
        // Seek backwards in the video
        NSLog("## Seek back 10 seconds")
        let currentTimeBack = avPlayer.currentTime()
        let seekTimeBack = CMTime(seconds: currentTimeBack.seconds - 10, preferredTimescale: 1)
        var seekTimeBefore = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        avPlayer.seek(to: seekTimeBack)
        Thread.sleep(forTimeInterval: 0.5)
        var seekTimeAfter = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        var seekTimeDiff = seekTimeAfter - seekTimeBefore
        // Expect that time has gone backwards 10 seconds
        #expect(seekTimeDiff <= -9000 && seekTimeDiff >= -11000)
        Thread.sleep(forTimeInterval: dispatchDelay)
        
        // Wait approximately 30 seconds
        NSLog("## Wait approximately 30 seconds")
        waitTimeBefore = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        Thread.sleep(forTimeInterval: 30.0)
        waitTimeAfter = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        waitTimeDiff = waitTimeAfter - waitTimeBefore
        // Expect that time difference is approximately 30 seconds
        #expect(waitTimeDiff >= 29000 && waitTimeDiff <= 31000)
        
        // Seek forwards in the video
        NSLog("## Seek forwards 20 seconds")
        let currentTimeForwards = avPlayer.currentTime()
        let seekTimeForwards = CMTime(seconds: currentTimeForwards.seconds + 20, preferredTimescale: 1)
        seekTimeBefore = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        avPlayer.seek(to: seekTimeForwards)
        Thread.sleep(forTimeInterval: 0.5)
        seekTimeAfter = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        seekTimeDiff = seekTimeAfter - seekTimeBefore
        // Expect that time has gone forwards 30 seconds
        #expect(waitTimeDiff >= 29000 && waitTimeDiff <= 31000)
        Thread.sleep(forTimeInterval: dispatchDelay)
        // Expect that MUXSDKSeekEvent was sent
        events = getEventsAndReset(for: playerName)
        let containsSeekEvent = events?.contains { $0 is MUXSDKSeekedEvent } ?? false
        #expect(containsSeekEvent)
        Thread.sleep(forTimeInterval: dispatchDelay)
        
        // Wait approximately 30 seconds
        NSLog("## Wait approximately 30 seconds")
        waitTimeBefore = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        Thread.sleep(forTimeInterval: 30.0)
        waitTimeAfter = getLatestTimeUpdateEvent(for: playerName)!.doubleValue
        waitTimeDiff = waitTimeAfter - waitTimeBefore
        // Expect that time difference is approximately 30 seconds
        #expect(waitTimeDiff >= 29000 && waitTimeDiff <= 31000)
        
        // Exit the player by going back to the menu
        // TBD: How to do this
    }
}
