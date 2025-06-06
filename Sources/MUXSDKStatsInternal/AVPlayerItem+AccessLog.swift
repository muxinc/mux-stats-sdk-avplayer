import AVFoundation

@available(iOS 15, tvOS 15, *)
extension AVPlayerItem {
    nonisolated var indicatedBitratesInAccessLog: some BidirectionalCollection<Double> {
        get async throws {
            while true {
                let indicatedBitrates = accessLog()?.events
                    .lazy
                    .map(\.indicatedBitrate)
                    .filter { $0 > .zero }

                if let indicatedBitrates, !indicatedBitrates.isEmpty {
                    return indicatedBitrates
                }

                try await withThrowingTaskGroup(of: Void.self) { group in
                    // Fail on status == .failed
                    group.addTask {
                        for await status in self.publisher(for: \.status, options: [.initial]).values {
                            if status == .failed {
                                throw StatusFailedError(playerItemError: self.error)
                            }
                        }
                    }

                    // Check again when this notification is posted
                    group.addTask {
                        _ = await NotificationCenter.default
                            .notifications(named: AVPlayerItem.newAccessLogEntryNotification,
                                           object: self)
                            .makeAsyncIterator()
                            .next()
                    }

                    defer {
                        group.cancelAll()
                    }

                    return try await group.nextResult()!.get()
                }
            }
        }
    }
}
