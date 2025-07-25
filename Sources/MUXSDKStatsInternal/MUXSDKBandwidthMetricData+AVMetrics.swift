import AVFoundation
import MuxCore

@available(iOS 18, tvOS 18, visionOS 2, *)
extension MUXSDKBandwidthMetricData {
    convenience init(metricEvent event: AVMetricEvent) {
        self.init()

        requestMediaStartTime = event.mediaTime.muxTimeValue
    }

    convenience init(mediaResourceRequestEvent event: AVMetricMediaResourceRequestEvent) {
        self.init(metricEvent: event)

        requestUrl = event.url?.absoluteString
        requestHostName = event.url?.host()

        requestStart = event.requestStartTime.muxTimeValue
        requestResponseStart = event.responseStartTime.muxTimeValue
        requestResponseEnd = event.responseEndTime.muxTimeValue

        requestBytesLoaded = event.byteRange.length as NSNumber

        requestResponseHeaders = event.networkTransactionMetrics?.transactionMetrics
            .compactMap { ($0.response as? HTTPURLResponse)?.allHeaderFields }
            .last

        if let errorEvent = event.errorEvent, !errorEvent.didRecover {
            let nsError = errorEvent.error as NSError

            requestError = nsError.domain
            requestErrorCode = nsError.code as NSNumber
            requestErrorText = nsError.localizedFailureReason ?? nsError.localizedDescription
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
    }

    convenience init?(event: AVMetricContentKeyRequestEvent) {
        guard let mediaResourceRequestEvent = event.mediaResourceRequestEvent else {
            return nil
        }

        self.init(mediaResourceRequestEvent: mediaResourceRequestEvent)

        requestType = "encryption"
    }
}
