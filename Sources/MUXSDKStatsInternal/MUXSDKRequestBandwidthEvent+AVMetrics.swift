//
//  MUXSDKRequestBandwidthEvent+AVMetrics.swift
//  MUXSDKStats
//
//  Created by Santiago Puppo on 18/6/25.
//
import AVFoundation
import MuxCore

extension MUXSDKRequestBandwidthEvent {
    convenience public init(accessLog event: AVPlayerItemAccessLogEvent, state: inout AccessLogToBandwidthMetricEventState) {
        self.init()
        self.type = MUXSDKPlaybackEventRequestBandwidthEventCompleteType
        self.bandwidthMetricData = MUXSDKBandwidthMetricData.init(accessLog: event, state: &state)
    }
}

@available(iOS 18, tvOS 18, visionOS 2, *)
extension MUXSDKRequestBandwidthEvent {
    convenience private init?(mediaResourceRequestEvent: AVMetricMediaResourceRequestEvent?) {
        guard let mediaResourceRequestEvent = mediaResourceRequestEvent else {
            return nil
        }
        
        self.init()
        self.setType(from: mediaResourceRequestEvent)
    }
    
    convenience public init?(event: AVMetricHLSPlaylistRequestEvent) {
        self.init(mediaResourceRequestEvent: event.mediaResourceRequestEvent)
        self.bandwidthMetricData = MUXSDKBandwidthMetricData.init(event: event)
    }
    
    convenience public init?(event: AVMetricHLSMediaSegmentRequestEvent) {
        self.init(mediaResourceRequestEvent: event.mediaResourceRequestEvent)
        self.bandwidthMetricData = MUXSDKBandwidthMetricData.init(event: event)
    }
    
    convenience public init?(event: AVMetricContentKeyRequestEvent) {
        self.init(mediaResourceRequestEvent: event.mediaResourceRequestEvent)
        self.bandwidthMetricData = MUXSDKBandwidthMetricData.init(event: event)
    }
    
    private func setType(from event: AVMetricMediaResourceRequestEvent) {
        if let error = event.errorEvent?.error as NSError? {
            if error.domain == NSURLErrorDomain && error.code == -999 {
                self.type = MUXSDKPlaybackEventRequestBandwidthEventCancelType
            } else {
                self.type = MUXSDKPlaybackEventRequestBandwidthEventErrorType
            }
        } else {
            self.type = MUXSDKPlaybackEventRequestBandwidthEventCompleteType
        }
    }
}
