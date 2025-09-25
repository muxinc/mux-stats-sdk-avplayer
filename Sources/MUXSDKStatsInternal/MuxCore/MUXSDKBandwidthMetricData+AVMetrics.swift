import AVFoundation
import MuxCore

@available(iOS 18, tvOS 18, visionOS 2, *)
extension MUXSDKBandwidthMetricData {
    convenience init(mediaResourceRequestEvent event: AVMetricMediaResourceRequestEvent) {
        self.init()

        requestUrl = event.url?.absoluteString
        requestHostName = event.url?.host()

        requestStart = event.requestStartTime.muxTimeValue
        requestResponseStart = event.responseStartTime.muxTimeValue
        requestResponseEnd = event.responseEndTime.muxTimeValue

        let lastTransactionMetrics = event.networkTransactionMetrics?.transactionMetrics.last

        requestBytesLoaded = lastTransactionMetrics.map {
            $0.countOfResponseHeaderBytesReceived + $0.countOfResponseBodyBytesReceived
        } as NSNumber?

        let lastHTTPResponse = lastTransactionMetrics?.response as? HTTPURLResponse

        requestResponseHeaders = lastHTTPResponse?.allHeaderFields

        if let errorEvent = event.errorEvent, !errorEvent.didRecover {
            requestError = errorEvent.error.localizedDescription

            if let lastHTTPResponse {
                requestErrorCode = lastHTTPResponse.statusCode as NSNumber
                requestErrorText = HTTPURLResponse.localizedString(forStatusCode: lastHTTPResponse.statusCode)
            }
        }
    }

    convenience init?(event: AVMetricHLSPlaylistRequestEvent) {
        guard let mediaResourceRequestEvent = event.mediaResourceRequestEvent else {
            return nil
        }

        self.init(mediaResourceRequestEvent: mediaResourceRequestEvent)

        requestType = "manifest"
    }

    convenience init?(event: AVMetricHLSMediaSegmentRequestEvent) {
        guard let mediaResourceRequestEvent = event.mediaResourceRequestEvent else {
            return nil
        }

        self.init(mediaResourceRequestEvent: mediaResourceRequestEvent)

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
            break
        }

#if compiler(>=6.2)
        if #available(iOS 26, tvOS 26, visionOS 26, *) {
            requestMediaDuration = event.segmentDuration.muxTimeValue
        }
#endif
    }

    convenience init?(event: AVMetricContentKeyRequestEvent) {
        guard let mediaResourceRequestEvent = event.mediaResourceRequestEvent else {
            return nil
        }

        self.init(mediaResourceRequestEvent: mediaResourceRequestEvent)

        requestType = "encryption"
    }
}
