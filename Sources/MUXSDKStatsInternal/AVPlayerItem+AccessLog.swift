import AVFoundation

@available(iOS 15, tvOS 15, *)
extension AVPlayerItem {

    nonisolated func waitForNewAccessLogEntry() async {
        _ = await NotificationCenter.default
            .notifications(named: AVPlayerItem.newAccessLogEntryNotification,
                           object: self)
            .makeAsyncIterator()
            .next()
    }

    nonisolated var playbackType: String {
        get async throws {
            while true {
                let playbackType = accessLog()?.events
                    .lazy
                    .compactMap(\.playbackType)
                    .last

                if let playbackType {
                    return playbackType
                }

                await waitForNewAccessLogEntry()

                try Task.checkCancellation()
            }
        }
    }

    nonisolated var playbackIsLive: Bool {
        get async throws {
            try await playbackType == "LIVE"
        }
    }

    nonisolated var mostRecentIndicatedBitrate: Double {
        get async throws {
            while true {
                let indicatedBitrate = accessLog()?.events
                    .lazy
                    .map(\.indicatedBitrate)
                    .filter { $0 > .zero }
                    .last

                if let indicatedBitrate {
                    return indicatedBitrate
                }

                await waitForNewAccessLogEntry()

                try Task.checkCancellation()
            }
        }
    }
}
