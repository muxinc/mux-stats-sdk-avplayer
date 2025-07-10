//
//  MUXSDKswift
//  MUXSDKStats
//
//  Created by Santiago Puppo on 17/6/25.
//
import AVFoundation
import MuxCore

public struct AccessLogToBandwidthMetricEventState {
    public var lastTransferDuration: TimeInterval = 0
    public var lastTransferredBytes: Int64 = 0
    
    public mutating func setLastTransferDuration(_ duration: TimeInterval) {
        lastTransferDuration = duration
    }
    
    public mutating func setLastTransferredBytes(_ bytes: Int64) {
        lastTransferredBytes = bytes
    }
}

extension MUXSDKBandwidthMetricData {
    convenience init(accessLog event: AVPlayerItemAccessLogEvent, state: inout AccessLogToBandwidthMetricEventState) {
        self.init()
        
        if let uri = event.uri, let url = URL(string: uri)  {
            switch url.pathExtension {
            case "m3u8":
                self.requestType = "manifest"
            default:
                self.requestType = "media"
            }
            
            self.requestHostName = url.host
            self.requestUrl = url.path
        }
        
        let requestCompletedTimeAprox = Date().timeIntervalSince1970
        let requestStartAprox = requestCompletedTimeAprox - event.transferDuration;
        
        self.requestStart = requestStartAprox as NSNumber
        self.requestResponseEnd = requestCompletedTimeAprox as NSNumber
        self.requestBytesLoaded = event.numberOfBytesTransferred - state.lastTransferredBytes as NSNumber
        
        state.setLastTransferDuration(event.transferDuration)
        state.setLastTransferredBytes(event.numberOfBytesTransferred)
    }
}

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
        
        self.requestStart = event.requestStartTime.timeIntervalSince1970 * 1000 as NSNumber
        self.requestResponseStart = event.responseStartTime.timeIntervalSince1970 * 1000 as NSNumber
        self.requestResponseEnd = event.responseEndTime.timeIntervalSince1970 * 1000 as NSNumber
        self.requestUrl = event.url?.path()
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
            if (event.isMapSegment) {
                requestType = "video_init"
            } else {
                requestType = "video"
            }
            break
        case .audio:
            if (event.isMapSegment) {
                requestType = "audio_init"
            } else {
                requestType = "audio"
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
        requestResponseStart = transactionMetrics.responseStartDate.map { $0.timeIntervalSince1970 * 1000 as NSNumber }
        requestResponseEnd = transactionMetrics.responseEndDate.map { $0.timeIntervalSince1970 * 1000 as NSNumber }
        requestUrl = transactionMetrics.request.url?.path()
        requestBytesLoaded = transactionMetrics.countOfResponseBodyBytesReceived + transactionMetrics.countOfResponseHeaderBytesReceived as NSNumber
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
        
        self.requestErrorCode = response.statusCode as NSNumber
        self.requestErrorText = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
    }
}
