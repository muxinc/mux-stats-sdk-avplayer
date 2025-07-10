//
//  BandwidthMetricEvents.swift
//  IntegrationTests
//
//  Created by Santiago Puppo on 4/7/25.
//

import Testing
import Combine

#if targetEnvironment(simulator)
nonisolated(unsafe) var testsAvailable : Bool = false
#else
nonisolated(unsafe) var testsAvailable : Bool = true
#endif

@Suite("Bandwidth Metric Events using AVMetrics", .enabled(if: testsAvailable)) struct BandwidthMetricEvents {
    struct NotSupportedError : Error {}
    let host = "localhost"
    let port = "8080"
    let baseUrl : URL
    
    init() async throws {
        baseUrl = URL(string: "http://" + host + ":" + port)!
    }
    
    func getTestUrl(_ path : String) throws -> URL  {
        if #available(iOS 16.0, *) {
            return baseUrl.appending(path: path)
        } else {
            throw NotSupportedError()
        }
    }
    
    func getRequestEvents(for playerName : String) -> [MUXSDKRequestBandwidthEvent] {
        getEvents(for: playerName).compactMap { event in
            return event as? MUXSDKRequestBandwidthEvent
        }
    }
    
    // "/test-cases/standard/ts-stream.m3u8"
    @Test("Standard TS Stream") func standardTSStream() async throws {
        guard #available(iOS 16.0, *) else {
            return
        }
        let playerName = "standard/ts-stream \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let vodURL = try getTestUrl("/test-cases/standard/ts-stream.m3u8")
        let avPlayer = AVPlayer(url: vodURL)
        binding.attach(avPlayer)
        await avPlayer.play()
        
        try await waitForPlaybackToStart(with: avPlayer, for: playerName)
        try await Task.sleep(for: .seconds(5))

        let requestEvents = getRequestEvents(for: playerName)

        let fiveCompleteEvents = requestEvents
            .filter { $0.type == MUXSDKPlaybackEventRequestBandwidthEventCompleteType }
            .count == 5
        let oneManifestEvent = requestEvents
            .compactMap{ $0.bandwidthMetricData }
            .filter { $0.requestType == "manifest" }
            .count == 1
        let fourVideoEvents = requestEvents
            .filter { $0.bandwidthMetricData?.requestType == "video" }
            .count == 4
        #expect(fiveCompleteEvents)
        #expect(oneManifestEvent)
        #expect(fourVideoEvents)
    }
    
    // "/test-cases/cmaf/index.m3u8"
    @Test func standardCmafStream() async throws {
        let playerName = "standard/cmaf \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let vodURL = try getTestUrl("/test-cases/cmaf/index.m3u8")
        let avPlayer = AVPlayer(url: vodURL)
        binding.attach(avPlayer)
        await avPlayer.play()
        
        try await waitForPlaybackToStart(with: avPlayer, for: playerName)
        
        let requestEvents = getRequestEvents(for: playerName)
        print(requestEvents)
    }
    
    // "/test-cases/input.mp4"
    @Test func standardMp4Stream() async throws {
        let playerName = "standard/mp4 \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
        let vodURL = try getTestUrl("/test-cases/input.mp4")
        let avPlayer = AVPlayer(url: vodURL)
        binding.attach(avPlayer)
        await avPlayer.play()
        
        try await waitForPlaybackToStart(with: avPlayer, for: playerName)
        
        let requestEvents = getRequestEvents(for: playerName)
    }
    // "/test-cases/standard/multi-variant.m3u8"
    // "/test-cases/standard/encrypted-stream.m3u8"
    // "/test-cases/input.mp4"
    // "/test-cases/http-codes/request-failed-stream.m3u8"
    // "/test-cases/http-codes/redirected-stream.m3u8"
    // "/test-cases/http-codes/request-canceled-stream.m3u8"
    // "/test-cases/cdn-change/index.m3u8"
}

