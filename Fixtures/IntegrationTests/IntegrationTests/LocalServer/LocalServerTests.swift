//
//  LocalServerTests.swift
//  IntegrationTests
//
//  Created by Santiago Puppo on 7/7/25.
//

import Testing

@Suite("Local Server Tests")
struct LocalServerTests {
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
    
    @Test func testNormalPath() async throws {
        let mockServer = MockHLSServer()
        try mockServer.start()
        defer { mockServer.stop() }
        
        print("Server started on: \(mockServer.baseURL)")
        
        let normalURL : URL = URL(string: mockServer.normalSegmentURL("segments/0.ts"))!
        print(normalURL)
        let (data, response) = try await URLSession.shared.data(from: normalURL)
        
        if let response = response as? HTTPURLResponse {
            #expect(response.statusCode == 200)
        }
    }
}
