import Testing
@testable import MUXSDKStats

struct IntegrationTests {
    @Test func createBinding() throws {
        let binding = MUXSDKPlayerBinding(playerName: "TestPlayerName", softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        _ = binding
    }
}
