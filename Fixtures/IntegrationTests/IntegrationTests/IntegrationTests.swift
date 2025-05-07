import Testing
@testable import MUXSDKStats

@Suite
struct IntegrationTests {
    @Test func createBinding() throws {
        let binding = MUXSDKPlayerBinding(playerName: "TestPlayerName", softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        _ = binding
    }
    
    func printEvents() {
        let events = MUXSDKCore.getEventsForPlayer("TestPlayerName")
        for event in events ?? [] {
            if event is MUXSDKTimeUpdateEvent ||
                event is MUXSDKRequestBandwidthEvent ||
                event is MUXSDKRenditionChangeEvent
            {
                continue // Skip not wanted events
            }
            NSLog(event.getType())
        }
        MUXSDKCore.resetCapturedEvents()
    }
    
    @Test func vodPlaybackTest() throws {
        MUXSDKCore.swizzleDispatchEvents()
        MUXSDKCore.resetCapturedEvents()

        let binding = MUXSDKPlayerBinding(playerName: "TestPlayerName", softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let VOD_URL = "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
        let avPlayer = AVPlayer(url: URL(string: VOD_URL)!)
        binding.attach(avPlayer)
                
        // Start playing VoD content
        NSLog("Start playing VoD content")
        avPlayer.play()
        printEvents()
        
        // Wait approximately 30 seconds
        NSLog("Wait approximately 30 seconds")
        Thread.sleep(forTimeInterval: 30.0)
        
        // Pause the content for 5 seconds
        NSLog("Pause the content for 5 seconds")
        avPlayer.pause()
        printEvents()
        Thread.sleep(forTimeInterval: 5.0)
        
        // Unpause the content
        NSLog("Unpause the content")
        avPlayer.play()
        printEvents()
        
        // Wait approximately 30 seconds
        NSLog("Wait approximately 30 seconds")
        Thread.sleep(forTimeInterval: 30.0)
        
        // Seek backwards in the video
        NSLog("Seek back")
        let currentTimeBack = avPlayer.currentTime()
        let seekTimeBack = CMTime(seconds: currentTimeBack.seconds - 10, preferredTimescale: 1)
        avPlayer.seek(to: seekTimeBack)
        printEvents()
        
        // Wait approximately 30 seconds
        NSLog("Wait approximately 30 seconds")
        Thread.sleep(forTimeInterval: 30.0)
        
        // Seek forwards in the video
        NSLog("Seek forwards")
        let currentTimeForwards = avPlayer.currentTime()
        let seekTimeForwards = CMTime(seconds: currentTimeForwards.seconds + 20, preferredTimescale: 1)
        avPlayer.seek(to: seekTimeForwards)
        printEvents()
        
        // Wait approximately 30 seconds
        NSLog("Wait approximately 30 seconds")
        Thread.sleep(forTimeInterval: 30.0)
        
        // Exit the player by going back to the menu
        // TBD: How to do this
    }
}
