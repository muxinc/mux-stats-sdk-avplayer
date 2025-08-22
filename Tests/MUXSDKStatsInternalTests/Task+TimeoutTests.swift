import Dispatch
import Foundation
import Testing
@testable import MUXSDKStatsInternal

struct TaskTimeoutTests {
    @Test func testTimeoutDoesNotFireImmediate() async throws {
        try await withTimeout(seconds: 0.1) {
            #expect(!Task.isCancelled, "operation should not be cancelled ")
        }
    }

    @Test func testTimeoutDoesNotFireYield() async throws {
        try await withTimeout(seconds: 0.1) {
            await Task.yield()
            #expect(!Task.isCancelled, "operation should not be cancelled ")
        }
    }

    @Test func testReturnsEarlyOnTimeoutNonBlocking() async throws {
        await withCheckedContinuation { endOfOperationContinuation in
            Task {
                var continuationThatTimesOut: CheckedContinuation<Void, Never>? = nil

                // waits forever if withTimeout doesn't return before its timed-out operation does
                _ = await #expect(throws: TimeoutError.self) {
                    try await withTimeout(seconds: 0.1) {
                        await withCheckedContinuation { continuationThatTimesOut = $0 }
                        #expect(Task.isCancelled, "timed-out operation should be cancelled ")
                        endOfOperationContinuation.resume()
                    }
                }

                continuationThatTimesOut?.resume()
            }
        }
    }

    @Test func testReturnsEarlyOnTimeoutBlocking() async throws {
        await withCheckedContinuation { endOfOperationContinuation in
            Task {
                let sempahore = DispatchSemaphore(value: 0)

                // waits forever if withTimeout doesn't return before its timed-out operation does
                _ = await #expect(throws: TimeoutError.self) {
                    try await withTimeout(seconds: 0.1) {
                        await withCheckedContinuation { continuation in
                            sempahore.wait()
                            continuation.resume()
                        }
                        #expect(Task.isCancelled, "timed-out operation should be cancelled ")
                        endOfOperationContinuation.resume()
                    }
                }

                sempahore.signal()
            }
        }
    }

    /*@Test func testTimeoutDoesNotFireCooperative() async throws {
        try await withTimeout(seconds: 0.1) {
            try await Task.sleep(nanoseconds: UInt64(NSEC_PER_MSEC * 25))
            #expect(!Task.isCancelled, "operation should not be cancelled ")
        }
    } */

    @Test func testTimeoutDoesNotFireNonBlocking() async throws {
        try await withTimeout(seconds: 0.1) {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .milliseconds(25)) {
                    continuation.resume()
                }
            }
            #expect(!Task.isCancelled, "operation should not be cancelled ")
        }
    }

    @Test func testTimeoutDoesNotFireBlocking() async throws {
        try await withTimeout(seconds: 0.1) {
            #expect(0 == usleep(25000))
            #expect(!Task.isCancelled, "operation should not be cancelled ")
        }
    }
}
