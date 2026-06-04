import AVFoundation
@testable import MUXSDKStatsInternal

extension AVPlayerItem {

    @available(iOS 15, tvOS 15, *)
    nonisolated(nonsending) func waitForReadyToPlay() async throws(StatusFailedError) {
        for await status in publisher(for: \.status, options: .initial).removeDuplicates().buffer(size: 2, prefetch: .byRequest, whenFull: .dropOldest).values {
            switch status {
            case .unknown:
                ()
            case .readyToPlay:
                return
            case .failed:
                throw StatusFailedError(playerItemError: error)
            @unknown default:
                fatalError("unknown status \(status)")
            }
        }
    }
}
