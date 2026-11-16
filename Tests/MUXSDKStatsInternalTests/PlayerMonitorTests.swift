import AVFoundation
import Foundation
@testable import MUXSDKStatsInternal
import Testing

@MainActor
struct PlayerMonitorTests {
    @available(iOS 15, tvOS 15, *)
    @Test(arguments: [false, true], [false, true])
    func cancellationDefersCleanupToMainQueue(releaseMonitor: Bool, fromBackground: Bool) async {
        let cleaned = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var monitor: PlayerMonitor? = PlayerMonitor(player: AVPlayer()) {
            [cleanup = CallbackCleanup(cleaned: cleaned)] _ in
            withExtendedLifetime(cleanup) {}
        }

        let cancel: @Sendable () -> Void = {
            if releaseMonitor {
                monitor = nil
            } else {
                monitor?.cancel()
            }
        }
        if fromBackground {
            let returned = DispatchSemaphore(value: 0)
            DispatchQueue.global().async {
                cancel()
                returned.signal()
            }
            // Keep the main queue occupied until background cancellation returns.
            #expect(wait(returned, timeout: .now() + 5) == .success)
        } else {
            cancel()
        }
        #expect(wait(cleaned) == .timedOut)

        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        #expect(wait(cleaned) == .success)
        withExtendedLifetime(monitor) {}
    }

    private func wait(_ semaphore: DispatchSemaphore, timeout: DispatchTime = .now()) -> DispatchTimeoutResult {
        semaphore.wait(timeout: timeout)
    }
}

private final class CallbackCleanup: Sendable {
    let cleaned: DispatchSemaphore

    init(cleaned: DispatchSemaphore) {
        self.cleaned = cleaned
    }

    deinit {
        #expect(Thread.isMainThread)
        cleaned.signal()
    }
}
