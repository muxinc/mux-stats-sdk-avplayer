//
//  BandwidthMetricEvents.swift
//  IntegrationTests
//
//  Created by Santiago Puppo on 4/7/25.
//

import Testing
import Combine

#if targetEnvironment(simulator)
@Suite("Bandwidth Metric Events using AVMetrics", .disabled("Needs a real device to run"))
#else
@Suite("Bandwidth Metric Events using AVMetrics")
#endif
struct BandwidthMetricEvents {
    struct NotSupportedError : Error {}
    
    let DEFAULT_TEST_WAIT_TIME = 5
    
    let host = ProcessInfo.processInfo.environment["TEST_HOST"] ?? "localhost"
    let port = ProcessInfo.processInfo.environment["TEST_PORT"] ?? "8080"
    let baseUrl : URL
    
    init() async throws {
        baseUrl = URL(string: "http://" + host + ":" + port)!
    }
    
    func getTestUrl(_ path : String) throws -> URL  {
        if #available(iOS 16.0, tvOS 16.0, *) {
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
    
    func commonExpectations(for completedEvents: [MUXSDKRequestBandwidthEvent])
    {
        let bandwidthMetricData = completedEvents.compactMap(\.bandwidthMetricData)

        let requestUrls = bandwidthMetricData.compactMap(\.requestUrl)
        let requestHostNames = bandwidthMetricData.compactMap(\.requestHostName)
        let orderedTimes = bandwidthMetricData.compactMap {
            [$0.requestStart, $0.requestResponseStart, $0.requestResponseEnd]
                .compactMap { $0 as? Int64 }
                .map { Date(milliseconds: $0) }
        }

        orderedTimes.forEach{
            print("Dates: \($0)")
        }

        #expect(requestUrls.toBeUnique())
        #expect(requestUrls.allSatisfy { $0.starts(with: self.baseUrl.absoluteString) })
        #expect(requestHostNames.allSatisfy { $0 == self.host })
        #expect(
            orderedTimes.allSatisfy {
                $0.count == 3 &&
                $0.toBeSorted(by: {
                    $0.compare($1) == .orderedAscending ||
                    $0.compare($1) == .orderedSame
                })
            }
        )
    }
    
    @available(iOS 16.0, tvOS 16.0, *)
    func setUpTest(for playerName: String, testCase: String) async throws -> AVPlayer {
        let vodURL = try getTestUrl(testCase)
        
        let avPlayer = AVPlayer()
        avPlayer.isMuted = true
        
        await MainActor.run(body: {
            let binding = MUXSDKPlayerBinding(playerName: playerName, softwareName: "TestSoftwareName", softwareVersion: "TestSoftwareVersion")
            binding.attach(avPlayer)
        })
        
        try await Task.sleep(for: .seconds(1))
        
        await MainActor.run(body: {
            let asset = AVURLAsset(url: vodURL)
            let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: [])
            avPlayer.replaceCurrentItem(with: playerItem)
        })
        return avPlayer
    }
    
    @available(iOS 16.0, tvOS 16.0, *)
    func playAndWait(for playerName : String, player avPlayer: AVPlayer) async throws -> [MUXSDKRequestBandwidthEvent] {
        do {
            await avPlayer.play()
            try await waitForPlaybackToStart(with: avPlayer, for: playerName)
            try await Task.sleep(for: .seconds(DEFAULT_TEST_WAIT_TIME))
        } catch {
            Issue.record("Playback did not start")
        }
        return getRequestEvents(for: playerName)
    }
    
    @available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
    @available(iOS, introduced: 18.0, message: "Needs AVMetrics to run")
    @Test("Standard TS Stream") func standardTSStream() async throws {
        let testCase = "/test-cases/standard/ts-stream.m3u8"
        let playerName = "\(testCase) \(UUID().uuidString)"
        
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let avPlayer = try await setUpTest(for: playerName, testCase: testCase)
        let requestEvents =  try await playAndWait(for: playerName, player: avPlayer)

        let completeEvents = requestEvents.completeEvents()
        let manifestEvents = requestEvents.manifestEvents()
        let videoEvents = requestEvents.segmentEvents(forType: "video")
            
        commonExpectations(for: completeEvents)
        #expect(completeEvents.count == 5)
        #expect(manifestEvents.count == 1)
        #expect(videoEvents.count == 4)
    }
    
    @available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
    @available(iOS, introduced: 18.0, message: "Needs AVMetrics to run")
    @Test("Standard CMAF Stream") func standardCmafStream() async throws {
        let testCase = "/test-cases/cmaf/index.m3u8"
        let playerName = "\(testCase) \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let avPlayer = try await setUpTest(for: playerName, testCase: testCase)
        let requestEvents = try await playAndWait(for: playerName, player: avPlayer)
        
        let completeEvents = requestEvents.completeEvents()
        let manifestEvents = requestEvents.manifestEvents()
        let videoEvents = requestEvents.segmentEvents(forType: "video")
        let audioEvents = requestEvents.segmentEvents(forType: "audio")
        let videoInitEvents = requestEvents.segmentEvents(forType: "video_init")
        let audioInitEvents = requestEvents.segmentEvents(forType: "audio_init")
        
        commonExpectations(for: completeEvents)
        #expect(completeEvents.count == 14)
        #expect(manifestEvents.count == 3)
        #expect(videoEvents.count == 4)
        #expect(videoInitEvents.count == 1)
        #expect(audioEvents.count == 5)
        #expect(audioInitEvents.count == 1)
    }
    
    @available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
    @available(iOS, introduced: 18.0, message: "Needs AVMetrics to run")
    @Test("Standard MP4 Stream") func standardMp4Stream() async throws {
        let testCase = "/test-cases/input.mp4"
        let playerName = "\(testCase) \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let avPlayer = try await setUpTest(for: playerName, testCase: testCase)
        let requestEvents =  try await playAndWait(for: playerName, player: avPlayer)
                
        // Should have one complete event created from access log
        let completeEvents = requestEvents.completeEvents()
        #expect(completeEvents.count == 1)
    }
    
    @available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
    @available(iOS, introduced: 18.0, message: "Needs AVMetrics to run")
    @Test("Standard Multi Variant Stream") func standardMultiVariantStream() async throws {
        let testCase = "/test-cases/standard/multi-variant.m3u8"
        let playerName = "\(testCase) \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let avPlayer = try await setUpTest(for: playerName, testCase: testCase)
        let requestEvents =  try await playAndWait(for: playerName, player: avPlayer)
        
        let completeEvents = requestEvents.completeEvents()
        let manifestEvents = requestEvents.manifestEvents()
        let videoEvents = requestEvents.segmentEvents(forType: "video")
        let manifestNames = manifestEvents.map{$0.bandwidthMetricData?.requestUrl}
        
        commonExpectations(for: completeEvents)
        /*
         I noticed during testing that multivariant streams may sometimes download all manifests.
         Mostly when running on repeat
         */
        #expect(completeEvents.count == 6 || completeEvents.count == 7)
        #expect(manifestEvents.count == 2 || manifestEvents.count == 3)
        #expect(videoEvents.count == 4)
        #expect(manifestNames.toBeUnique())
    }
    
    @available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
    @available(iOS, introduced: 18.0, message: "Needs AVMetrics to run")
    @Test("Standard Encrypted Stream") func standardEncryptedStream() async throws {
        let testCase = "/test-cases/standard/encrypted-stream.m3u8"
        let playerName = "\(testCase) \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let avPlayer = try await setUpTest(for: playerName, testCase: testCase)
        let requestEvents =  try await playAndWait(for: playerName, player: avPlayer)
        
        let completeEvents = requestEvents.completeEvents()
        let manifestEvents = requestEvents.manifestEvents()
        let videoEvents = requestEvents.segmentEvents(forType: "video")
        let contentKeyEvents = requestEvents.encryptionEvents()
        
        commonExpectations(for: completeEvents)
        #expect(completeEvents.count == 6)
        #expect(manifestEvents.count == 1)
        #expect(videoEvents.count == 4)
        #expect(contentKeyEvents.count == 1)
    }
    
    @available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
    @available(iOS, introduced: 18.0, message: "Needs AVMetrics to run")
    @Test("Failed Requests Test Stream") func requestFailedStream() async throws {
        let testCase = "/test-cases/http-codes/request-failed-stream.m3u8"
        let playerName = "\(testCase) \(UUID().uuidString)"
        
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let avPlayer = try await setUpTest(for: playerName, testCase: testCase)
        let requestEvents =  try await playAndWait(for: playerName, player: avPlayer)
        
        let completeEvents = requestEvents.completeEvents()
        let manifestEvents = requestEvents.manifestEvents()
        let videoEvents = requestEvents.segmentEvents(forType: "video")
        let failedEvents = requestEvents.failedEvents()
        
        commonExpectations(for: completeEvents)
        #expect(requestEvents.count == 5)
        #expect(completeEvents.count == 2)
        #expect(failedEvents.count == 3)
        
        #expect(manifestEvents.count == 1)
        #expect(videoEvents.count == 4)
    }
    
    @available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
    @available(iOS, introduced: 18.0, message: "Needs AVMetrics to run")
    @Test("Redirected Requests Test Stream") func requestRedirectedStream() async throws {
        let testCase = "/redirect/test-cases/http-codes/redirected-stream.m3u8"
        let playerName = "\(testCase) \(UUID().uuidString)"
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let avPlayer = try await setUpTest(for: playerName, testCase: testCase)
        let requestEvents =  try await playAndWait(for: playerName, player: avPlayer)
        
        let completeEvents = requestEvents.completeEvents()
        let manifestEvents = requestEvents.manifestEvents()
        let videoEvents = requestEvents.segmentEvents(forType: "video")
        
        commonExpectations(for: completeEvents)
        #expect(completeEvents.count == 3)
        #expect(manifestEvents.count == 1)
        #expect(videoEvents.count == 2)
    }
    
    @available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
    @available(iOS, introduced: 18.0, message: "Needs AVMetrics to run")
    @Test("Canceled Request Stream", .disabled("Couldn't figure how to forcefully cancel a request")) func requestCanceledStream() async throws {
        let testCase = "/test-cases/http-codes/request-canceled-stream.m3u8"
        let playerName = "\(testCase) \(UUID().uuidString)"
        
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let avPlayer = try await setUpTest(for: playerName, testCase: testCase)
        await avPlayer.play()
        try await waitForPlaybackToStart(with: avPlayer, for: playerName)
        try await Task.sleep(for: .seconds(DEFAULT_TEST_WAIT_TIME))
        try await MainActor.run(body: {
            let newURL = try getTestUrl("/not-found/this-stream-doesnt-exist.m3u8")
            let asset = AVURLAsset(url: newURL)
            let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: [])
            avPlayer.replaceCurrentItem(with: playerItem)
        })
        try await Task.sleep(for: .seconds(2))
        
        let requestEvents = getRequestEvents(for: playerName)
        
        let completeEvents = requestEvents.completeEvents()
        let canceledEvents = requestEvents.canceledEvents()
        
        commonExpectations(for: completeEvents)
        #expect(completeEvents.count == 3)
        #expect(canceledEvents.count == 1)
    }
    
    @available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
    @available(iOS, introduced: 18.0, message: "Needs AVMetrics to run")
    @Test("CDN Change Stream") func cdnChangeStream() async throws {
        let testCase = "/test-cases/cdn-change/index.m3u8"
        let playerName = "\(testCase) \(UUID().uuidString)"
        
        MUXSDKCore.swizzleDispatchEvents()
        defer {
            MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
        }
        
        let avPlayer = try await setUpTest(for: playerName, testCase: testCase)
        let requestEvents =  try await playAndWait(for: playerName, player: avPlayer)
        
        let completeEvents = requestEvents.completeEvents()
        let manifestEvents = requestEvents.manifestEvents()
        let videoEvents = requestEvents.segmentEvents(forType: "video")
        
        commonExpectations(for: completeEvents)
        #expect(completeEvents.count == 8)
        #expect(manifestEvents.count == 3)
        #expect(videoEvents.count == 6)
    }
}

extension Array where Element: MUXSDKRequestBandwidthEvent {
    func completeEvents() -> [MUXSDKRequestBandwidthEvent] {
        filter { $0.type == MUXSDKPlaybackEventRequestBandwidthEventCompleteType }
    }
    
    func failedEvents() -> [MUXSDKRequestBandwidthEvent] {
        filter { $0.type == MUXSDKPlaybackEventRequestBandwidthEventErrorType }
    }
    
    func canceledEvents() -> [MUXSDKRequestBandwidthEvent] {
        filter { $0.type == MUXSDKPlaybackEventRequestBandwidthEventCancelType }
    }
    
    func manifestEvents() -> [MUXSDKRequestBandwidthEvent] {
        filter{ $0.bandwidthMetricData?.requestType == "manifest" }
    }
        
    func segmentEvents(forType requestType : String) -> [MUXSDKRequestBandwidthEvent] {
        filter{ $0.bandwidthMetricData?.requestType == requestType }
    }
    
    func encryptionEvents() -> [MUXSDKRequestBandwidthEvent] {
        filter { $0.bandwidthMetricData?.requestType == "encryption" }
    }
    
    func print() {
        map {ev in "\(ev.type!) - \(ev.bandwidthMetricData!.requestUrl!)"}
            .forEach { Swift.print($0 + "\n") }
    }
}

extension Array where Element : Hashable {
    func toBeUnique() -> Bool {
        Set(self).count == self.count
    }
    
    func toBeSorted(by: (Element, Element) throws -> Bool) rethrows -> Bool where Element : Hashable {
       try self.sorted(by: by) == self
    }
}

extension Date {
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}
