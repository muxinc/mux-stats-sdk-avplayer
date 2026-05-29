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
                let semaphore = DispatchSemaphore(value: 0)

                let taskThatWaits = Task {
                    await withCheckedContinuation { continuation in
                        semaphore.wait()
                        continuation.resume()
                    }
                }

                // waits forever if withTimeout doesn't return before its timed-out operation does
                _ = await #expect(throws: TimeoutError.self) {
                    try await withTimeout(seconds: 0.1) {
                        await taskThatWaits.value
                        #expect(Task.isCancelled, "timed-out operation should be cancelled ")
                        endOfOperationContinuation.resume()
                    }
                }

                #expect(semaphore.signal() != 0)
            }
        }
    }

    @Test func testReturnsEarlyOnTimeoutBlocking() async throws {
        await withCheckedContinuation { endOfOperationContinuation in
            Task {
                let semaphore = DispatchSemaphore(value: 0)

                // waits forever if withTimeout doesn't return before its timed-out operation does
                _ = await #expect(throws: TimeoutError.self) {
                    try await withTimeout(seconds: 0.1) {
                        await withCheckedContinuation { continuation in
                            semaphore.wait()
                            continuation.resume()
                        }
                        #expect(Task.isCancelled, "timed-out operation should be cancelled ")
                        endOfOperationContinuation.resume()
                    }
                }

                #expect(semaphore.signal() != 0)
            }
        }
    }

    @Test func testTimeoutDoesNotFireNonBlocking() async throws {
        try await withTimeout(seconds: 0.25) {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .milliseconds(25)) {
                    continuation.resume()
                }
            }
            #expect(!Task.isCancelled, "operation should not be cancelled ")
        }
    }

    @Test func testTimeoutDoesNotFireBlocking() async throws {
        try await withTimeout(seconds: 0.25) {
            #expect(0 == usleep(25000))
            #expect(!Task.isCancelled, "operation should not be cancelled ")
        }
    }

    @Test func testPropagatesParentCancellation() async throws {
        try await confirmation { wasCancelled in
            let operationStartedSemaphore = DispatchSemaphore(value: 0)

            let parent = Task {
                try await withTimeout(seconds: 5) {
                    await withTaskCancellationHandler {
                        #expect(!Task.isCancelled)
                        #expect(operationStartedSemaphore.signal() != 0)
                        while !Task.isCancelled {
                            await Task.yield()
                        }
                    } onCancel: {
                        wasCancelled.confirm()
                    }
                }
            }

            // wait for operation to begin
            await withCheckedContinuation { continuation in
                operationStartedSemaphore.wait()
                continuation.resume()
            }

            parent.cancel()

            try await parent.value
        }
    }

    @Test func testPropagatesAlreadyCancelledParent() async throws {
        let parent = Task {
            while !Task.isCancelled {
                await Task.yield()
            }

            try await withTimeout(seconds: 5) {
                #expect(Task.isCancelled)
            }
        }

        parent.cancel()

        try await parent.value
    }
}
