import AVFoundation
import os

@available(iOS 14, tvOS 14, *)
let logger = Logger(subsystem: "com.mux.stats-avplayer", category: "general")

extension CMTime {
    var loggable: String {
        CMTimeCopyDescription(allocator: nil, time: self) as String? ?? ""
    }
}

extension AVPlayer.Status {
    var loggable: String {
        switch self {
        case .readyToPlay:
            ".readyToPlay"
        case .failed:
            ".failed"
        case .unknown:
            ".unknown"
        @unknown default:
            "AVPlayer.Status(rawValue: \(self.rawValue)"
        }
    }
}

extension AVPlayer.TimeControlStatus {
    var loggable: String {
        switch self {
        case .paused:
            ".paused"
        case .waitingToPlayAtSpecifiedRate:
            ".waitingToPlayAtSpecifiedRate"
        case .playing:
            ".playing"
        @unknown default:
            "AVPlayer.TimeControlStatus(rawValue: \(self.rawValue)"
        }
    }
}

extension AVPlayerItem.Status {
    var loggable: String {
        switch self {
        case .readyToPlay:
            ".readyToPlay"
        case .failed:
            ".failed"
        case .unknown:
            ".unknown"
        @unknown default:
            "AVPlayerItem.Status(rawValue: \(self.rawValue)"
        }
    }
}
