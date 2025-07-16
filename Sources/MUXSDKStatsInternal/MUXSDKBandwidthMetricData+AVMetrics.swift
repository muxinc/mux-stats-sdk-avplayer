//
//  MUXSDKBandwidthMetricData+AVMetrics.swift
//  MUXSDKStats
//
//  Created by Santiago Puppo on 17/6/25.
//
public import AVFoundation
public import MuxCore

@available(iOS 18, tvOS 18, visionOS 2, *)
extension MUXSDKBandwidthMetricData {
    convenience public init?(mediaResourceRequestEvent event: AVMetricMediaResourceRequestEvent?) {
        self.init()
                
        guard let event = event else {
            return nil
        }
        
        if let errorEvent = event.errorEvent?.error {
            requestError = errorEvent.localizedDescription
            let nsErr = errorEvent as NSError
            
            if nsErr.domain == NSURLErrorDomain {
                requestErrorCode = nsErr.code as NSNumber
                requestErrorText = nsErr.localizedFailureReason
            }
            
            event.networkTransactionMetrics?.transactionMetrics.forEach {
                loadErrorMetrics(from: $0)
            }
        }
        
        self.requestStart = event.requestStartTime.millisecondsSince1970 as NSNumber
        self.requestResponseStart = event.responseStartTime.millisecondsSince1970 as NSNumber
        self.requestResponseEnd = event.responseEndTime.millisecondsSince1970 as NSNumber
        self.requestUrl = event.url?.absoluteString
        self.requestBytesLoaded = event.byteRange.length as NSNumber
        self.requestHostName = event.url?.host()
        
        event.networkTransactionMetrics?.transactionMetrics.forEach {
            self.loadHeaders(from: $0)
        }
    }
    
    convenience public init?(event: AVMetricHLSPlaylistRequestEvent) {
        self.init(mediaResourceRequestEvent: event.mediaResourceRequestEvent)
        self.requestType = "manifest"
    }
    
    convenience public init?(event: AVMetricHLSMediaSegmentRequestEvent) {
        self.init(mediaResourceRequestEvent: event.mediaResourceRequestEvent)
        
        switch event.mediaType {
        case .video:
            requestType = event.isMapSegment ? "video_init" : "video"
        case .audio:
            requestType = event.isMapSegment ? "audio_init" : "audio"
        case .text, .closedCaption, .subtitle:
            requestType = "subtitle"
        case .muxed:
            requestType = "media"
        default:
            requestType = nil
        }
    }
    
    convenience public init?(event: AVMetricContentKeyRequestEvent) {
        self.init(mediaResourceRequestEvent: event.mediaResourceRequestEvent)
        
        self.requestType = "encryption"
    }
    
    // Currently unused. Could be used if we want to track redirects separetly
    convenience public init?(from transactionMetrics: URLSessionTaskTransactionMetrics) {
        self.init()
        
        requestStart = transactionMetrics.fetchStartDate.map { NSNumber(value: $0.millisecondsSince1970) }
        requestResponseStart = transactionMetrics.responseStartDate.map { $0.millisecondsSince1970 as NSNumber }
        requestResponseEnd = transactionMetrics.responseEndDate.map { $0.millisecondsSince1970 as NSNumber }
        requestUrl = transactionMetrics.request.url?.absoluteString
        requestBytesLoaded = transactionMetrics.countOfResponseBodyBytesReceived + transactionMetrics.countOfResponseHeaderBytesReceived as NSNumber
        requestHostName = transactionMetrics.request.url?.host()
        
        loadHeaders(from: transactionMetrics)
    }
    
    func loadHeaders(from metricEvent: URLSessionTaskTransactionMetrics) {
        guard let response = metricEvent.response as? HTTPURLResponse else {
            return
        }
        
        self.requestResponseHeaders = response.allHeaderFields
    }
    
    func loadErrorMetrics(from metricEvent: URLSessionTaskTransactionMetrics) {
        guard let response = metricEvent.response as? HTTPURLResponse else {
            return
        }
        
        self.requestErrorCode = response.statusCode as NSNumber
        self.requestErrorText = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
    }
}

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}
