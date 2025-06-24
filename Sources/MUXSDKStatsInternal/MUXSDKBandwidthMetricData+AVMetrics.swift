//
//  MUXSDKswift
//  MUXSDKStats
//
//  Created by Santiago Puppo on 17/6/25.
//
import AVFoundation
import MuxCore

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
                requestErrorCode = NSNumber.init(value:nsErr.code)
                requestErrorText = nsErr.localizedFailureReason
            }
            
            event.networkTransactionMetrics?.transactionMetrics.forEach {
                loadErrorMetrics(from: $0)
            }
        }
        
        self.requestStart = NSNumber.init(value: event.requestStartTime.timeIntervalSince1970 * 1000)
        self.requestResponseStart = NSNumber.init(value: event.responseStartTime.timeIntervalSince1970 * 1000)
        self.requestResponseEnd = NSNumber.init(value: event.responseEndTime.timeIntervalSince1970 * 1000)
        self.requestUrl = event.url?.path()
        self.requestBytesLoaded = NSNumber.init(value: event.byteRange.length)
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
            if (event.isMapSegment) {
                requestType = "video"
            } else {
                requestType = "video_init"
            }
            break
        case .audio:
            if (event.isMapSegment) {
                requestType = "audio"
            } else {
                requestType = "audio_init"
            }
            break
        case .text, .closedCaption, .subtitle:
            requestType = "subtitle"
            break
        case .muxed:
            requestType = "media"
            break
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
        
        requestStart = transactionMetrics.fetchStartDate.map { NSNumber(value: $0.timeIntervalSince1970 * 1000) }
        requestResponseStart = transactionMetrics.responseStartDate.map { NSNumber.init(value: $0.timeIntervalSince1970 * 1000) }
        requestResponseEnd = transactionMetrics.responseEndDate.map { NSNumber.init(value: $0.timeIntervalSince1970 * 1000) }
        requestUrl = transactionMetrics.request.url?.path()
        requestBytesLoaded = NSNumber.init(value: transactionMetrics.countOfResponseBodyBytesReceived + transactionMetrics.countOfResponseHeaderBytesReceived)
        requestHostName = transactionMetrics.request.url?.host()
        
        loadHeaders(from: transactionMetrics)
    }
    
    // TODO: Test redirects
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
        
        self.requestErrorCode = NSNumber.init(value: response.statusCode)
        self.requestErrorText = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
    }
}
