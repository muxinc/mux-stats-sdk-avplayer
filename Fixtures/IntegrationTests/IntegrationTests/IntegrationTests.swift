import Testing
@testable import MUXSDKStats

@Suite
struct IntegrationTests {
    @Test func createBinding() throws {
        let binding = MUXSDKPlayerBinding(playerName: "TestPlayerName", softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        _ = binding
    }
    
    @Test func avPlayer() throws {
        MUXSDKCore.swizzleDispatchEvents()
        MUXSDKCore.resetCapturedEvents()

        let binding = MUXSDKPlayerBinding(playerName: "TestPlayerName", softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let MEDIA_URL = "https://stream.mux.com/v69RSHhFelSm4701snP22dYz2jICy4E4FUyk02rW4gxRM.m3u8"
        let avPlayer = AVPlayer(url: URL(string: MEDIA_URL)!)
        binding.attach(avPlayer)
//        
//        binding.dispatchPlay()
//        
//        let eventCount = MUXSDKCore.eventsCount(forPlayer: "TestPlayerName")
//        NSLog(eventCount.description)
//        if(eventCount > 0){
//            let event = MUXSDKCore.event(at: 0, forPlayer: "TestPlayerName")
//            NSLog("%@", event?.getType() ?? "nil")
//        }
        
        avPlayer.play()
        
        // catch the events
    }
}
