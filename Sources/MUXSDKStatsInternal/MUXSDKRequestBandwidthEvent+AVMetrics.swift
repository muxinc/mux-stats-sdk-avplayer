import AVFoundation
import MuxCore

@available(iOS 18, tvOS 18, visionOS 2, *)
extension AVMetricMediaResourceRequestEvent {
    var requestBandwidthEventType: String {
        if let errorEvent, !errorEvent.didRecover {
            if let error = errorEvent.error as? URLError,
               error.code == .cancelled {
                return MUXSDKPlaybackEventRequestBandwidthEventCancelType
            }
            return MUXSDKPlaybackEventRequestBandwidthEventErrorType
        }
        return MUXSDKPlaybackEventRequestBandwidthEventCompleteType
    }
}

@available(iOS 18, tvOS 18, visionOS 2, *)
extension MUXSDKRequestBandwidthEvent {
    convenience init?(event: AVMetricHLSPlaylistRequestEvent) {
        guard let mediaResourceRequestEvent = event.mediaResourceRequestEvent,
              let bandwidthMetricData = MUXSDKBandwidthMetricData(event: event) else {
            return nil
        }

        self.init()

        type = mediaResourceRequestEvent.requestBandwidthEventType
        self.bandwidthMetricData = bandwidthMetricData
    }

    convenience init?(event: AVMetricHLSMediaSegmentRequestEvent) {
        guard let mediaResourceRequestEvent = event.mediaResourceRequestEvent,
              let bandwidthMetricData = MUXSDKBandwidthMetricData(event: event) else {
            return nil
        }

        self.init()

        type = mediaResourceRequestEvent.requestBandwidthEventType
        self.bandwidthMetricData = bandwidthMetricData
    }

    convenience init?(event: AVMetricContentKeyRequestEvent) {
        guard let mediaResourceRequestEvent = event.mediaResourceRequestEvent,
              let bandwidthMetricData = MUXSDKBandwidthMetricData(event: event) else {
            return nil
        }

        self.init()

        type = mediaResourceRequestEvent.requestBandwidthEventType
        self.bandwidthMetricData = bandwidthMetricData
    }
}
