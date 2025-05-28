import Dispatch
import Foundation
import Testing
@testable import MUXSDKStatsInternal

struct TaskTimeoutTests {
    @Test func testTimeoutDoesNotFireImmediate() async throws {
        try await withTimeout(of: 0.1) {
            #expect(!Task.isCancelled, "operation should not be cancelled ")
        }
    }


    @Test func testTimeoutFiresNonBlocking() async throws {
        await #expect(throws: TimeoutError.self) {
            try await withTimeout(of: 0.1) {
                await withCheckedContinuation { continuation in
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                        continuation.resume()
                    }
                }
                #expect(Task.isCancelled, "timed-out operation should be cancelled ")
            }
        }
    }

    @Test func testTimeoutDoesNotFireNonBlocking() async throws {
        try await withTimeout(of: 0.1) {
            await withCheckedContinuation { continuation in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(25)) {
                    continuation.resume()
                }
            }
            #expect(!Task.isCancelled, "operation should not be cancelled ")
        }
    }

    @Test func testTimeoutFiresBlocking() async throws {
        await #expect(throws: TimeoutError.self) {
            try await withTimeout(of: 0.1) {
                #expect(0 == usleep(500000))
            }
            #expect(Task.isCancelled, "timed-out operation should be cancelled ")
        }
    }

    @Test func testTimeoutDoesNotFireBlocking() async throws {
        try await withTimeout(of: 0.1) {
            #expect(0 == usleep(25000))
        }
        #expect(!Task.isCancelled, "operation should not be cancelled ")
    }
}
