//
//  LocalServerTests.swift
//  IntegrationTests
//
//  Created by Santiago Puppo on 7/7/25.
//

import Testing
import IntegrationTestUtilities

@Suite("Local Server Tests")
struct LocalServerTests {
    @Test func mockServerDynamicSegmentsTest() async throws {
        let mockServer = MockHLSServer()
        
        try mockServer.start()
        defer { mockServer.stop() }
        
        // Normal segments
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
        
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        let events1 = getEventsAndReset(for: playerName1)
        binding1.detachAVPlayer()
        
        // Failing segments
        let playerName2 = "failingSegments \(UUID().uuidString)"
        MUXSDKCore.resetCapturedEvents(forPlayer: playerName2)
        
        let binding2 = MUXSDKPlayerBinding(playerName: playerName2, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let failingURL = mockServer.failingSegmentsURL
        
        let avPlayer2 = AVPlayer(url: URL(string: failingURL)!)
        binding2.attach(avPlayer2)
        
        await MainActor.run {
            avPlayer2.play()
        }
        
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        let events2 = getEventsAndReset(for: playerName2)
        binding2.detachAVPlayer()
        
        // Proxy functionality
        let proxyURL = mockServer.proxyURL(path: "VcmKA6aqzIzlg3MayLJDnbF55kX00mds028Z65QxvBYaA.m3u8", host: "stream.mux.com")
        
        let playerName3 = "proxyPlayer \(UUID().uuidString)"
        MUXSDKCore.resetCapturedEvents(forPlayer: playerName3)
        
        let binding3 = MUXSDKPlayerBinding(playerName: playerName3, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let avPlayer3 = AVPlayer(url: URL(string: proxyURL)!)
        binding3.attach(avPlayer3)
        
        await MainActor.run {
            avPlayer3.play()
        }
        
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        let events3 = getEventsAndReset(for: playerName3)
        binding3.detachAVPlayer()
        
        #expect(events1 != nil, "Expected some events from normal segments")
        #expect(events2 != nil, "Expected some events from failing segments")
        #expect(events3 != nil, "Expected some events from proxy")
    }
    
    @Test func fileLoadingWorks() async throws {
        let mockServer = MockHLSServer()
        try mockServer.start()
        defer { mockServer.stop() }
        
        // Test CMAF video segment
        let cmafVideoFile = "cmaf/video/0.m4s"
        let cmafVideoUrl = URL(string: mockServer.normalSegmentURL(cmafVideoFile))!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: cmafVideoUrl)
            if let response = response as? HTTPURLResponse {
                print("Response: \(response.statusCode), Data size: \(data.count) bytes")
                #expect(response.statusCode == 200, "Expected HTTP 200, got \(response.statusCode)")
                #expect(data.count > 0, "Expected data size > 0, got \(data.count) bytes")
            } else {
                #expect(false, "No HTTP response received")
            }
        } catch {
            #expect(false, "Request failed with error: \(error)")
        }
        
        // Test segments video segment
        let segmentsVideoFile = "segments/0.ts"
        let segmentsVideoUrl = URL(string: mockServer.normalSegmentURL(segmentsVideoFile))!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: segmentsVideoUrl)
            if let response = response as? HTTPURLResponse {
                print("Response: \(response.statusCode), Data size: \(data.count) bytes")
                #expect(response.statusCode == 200)
                #expect(data.count > 0)
            } else {
                print("No HTTP response received")
            }
        } catch {
            print("Request failed with error: \(error)")
            throw error
        }
        
        // Test multivariant master playlist
        let multivariantMasterFile = "multivariant/index.m3u8"
        let multivariantMasterUrl = URL(string: mockServer.normalSegmentURL(multivariantMasterFile))!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: multivariantMasterUrl)
            if let response = response as? HTTPURLResponse {
                print("Response: \(response.statusCode), Data size: \(data.count) bytes")
                #expect(response.statusCode == 200)
                #expect(data.count > 0)
            } else {
                print("No HTTP response received")
            }
        } catch {
            print("Request failed with error: \(error)")
            throw error
        }
        
        // Test encrypted playlist
        let encryptedPlaylistFile = "encrypted/index.m3u8"
        let encryptedPlaylistUrl = URL(string: mockServer.normalSegmentURL(encryptedPlaylistFile))!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: encryptedPlaylistUrl)
            if let response = response as? HTTPURLResponse {
                print("Response: \(response.statusCode), Data size: \(data.count) bytes")
                #expect(response.statusCode == 200)
                #expect(data.count > 0)
            } else {
                print("No HTTP response received")
            }
        } catch {
            print("Request failed with error: \(error)")
            throw error
        }
    }
    
    @Test func diagnosticAssetsPath() {
        let assetsPath = IntegrationTestAssets.assetsPath
        print("Assets path: \(assetsPath)")
        
        // Check if the assets directory exists
        let fileManager = FileManager.default
        let assetsExists = fileManager.fileExists(atPath: assetsPath)
        #expect(assetsExists, "Assets directory does not exist at: \(assetsPath)")
        
        // Check if specific files exist
        let testFiles = [
            "cmaf/video/0.m4s",
            "segments/0.ts", 
            "multivariant/index.m3u8",
            "encrypted/index.m3u8"
        ]
        
        for testFile in testFiles {
            let fullPath = "\(assetsPath)/\(testFile)"
            let fileExists = fileManager.fileExists(atPath: fullPath)
            print("File \(testFile): \(fileExists ? "EXISTS" : "MISSING") at \(fullPath)")
            #expect(fileExists, "Test file \(testFile) does not exist at: \(fullPath)")
        }
    }
}
