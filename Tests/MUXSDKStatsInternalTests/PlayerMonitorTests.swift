import Combine
import Foundation
import MuxCore
import Testing
@testable import MUXSDKStatsInternal

@MainActor
struct PlayerMonitorTests {
    @Test
    func backgroundCancellationSkipsEventsAndDefersCleanup() async {
        guard #available(iOS 15, tvOS 15, *) else { return }
        let events = PassthroughSubject<MUXSDKBaseEvent, Never>()
        let cancelled = DispatchSemaphore(value: 0)
        let callbackReleasedOnMain = DispatchSemaphore(value: 0)
        var receivedCount = 0
        nonisolated(unsafe) let monitor = PlayerMonitor(
            events: events.handleEvents(receiveCancel: {
                #expect(Thread.isMainThread)
                cancelled.signal()
            }).eraseToAnyPublisher(),
            onEvent: { [lifetime = CallbackLifetime(releasedOnMain: callbackReleasedOnMain)] _ in
                withExtendedLifetime(lifetime) { receivedCount += 1 }
            })

        events.send(MUXSDKBaseEvent())
        #expect(receivedCount == 1)

        // Hold the main queue until background cancellation has returned.
        let returned = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            monitor.cancel()
            monitor.cancel()
            returned.signal()
        }
        #expect(wait(returned, timeout: .now() + 5) == .success)
        #expect(wait(cancelled) == .timedOut)
        events.send(MUXSDKBaseEvent())
        #expect(receivedCount == 1)

        await drainMainQueue()
        #expect(wait(cancelled) == .success)
        #expect(wait(callbackReleasedOnMain) == .success)
    }

    @Test
    func backgroundReleaseDuringCallbackKeepsMonitorAlive() async {
        guard #available(iOS 15, tvOS 15, *) else { return }
        let events = PassthroughSubject<MUXSDKBaseEvent, Never>()
        let cancelled = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var monitor: PlayerMonitor?
        nonisolated(unsafe) weak var weakMonitor: PlayerMonitor?
        var receivedCount = 0
        monitor = PlayerMonitor(
            events: events.handleEvents(receiveCancel: {
                #expect(Thread.isMainThread)
                cancelled.signal()
            }).eraseToAnyPublisher(),
            onEvent: { _ in
                receivedCount += 1
                let released = DispatchSemaphore(value: 0)
                DispatchQueue.global().async {
                    monitor = nil
                    released.signal()
                }
                #expect(released.wait(timeout: .now() + 5) == .success)
                #expect(weakMonitor != nil)
                #expect(cancelled.wait(timeout: .now()) == .timedOut)
            })
        weakMonitor = monitor

        events.send(MUXSDKBaseEvent())
        await drainMainQueue()
        #expect(weakMonitor == nil)
        #expect(wait(cancelled) == .success)
        events.send(MUXSDKBaseEvent())
        #expect(receivedCount == 1)
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    // Deliberately block the main queue to make background teardown overlap deterministic.
    private func wait(_ semaphore: DispatchSemaphore, timeout: DispatchTime = .now()) -> DispatchTimeoutResult {
        semaphore.wait(timeout: timeout)
    }
}

private final class CallbackLifetime: Sendable {
    let releasedOnMain: DispatchSemaphore

    init(releasedOnMain: DispatchSemaphore) {
        self.releasedOnMain = releasedOnMain
    }

    deinit {
        if Thread.isMainThread { releasedOnMain.signal() }
    }
}
