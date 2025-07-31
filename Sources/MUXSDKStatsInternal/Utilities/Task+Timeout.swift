import Foundation

struct TimeoutError: Error {
}

@available(iOS 13, tvOS 13, *)
func withTimeout<T: Sendable>(seconds: TimeInterval, operation: sending @escaping @isolated(any) () async throws -> T) async throws -> T {
    let workTask = Task {
        try await operation()
    }
    return try await withCheckedThrowingContinuation { continuation in
        Task {
            await withThrowingTaskGroup(of: T.self) { group in
                defer {
                    workTask.cancel()
                    group.cancelAll()
                }
                group.addTask {
                    try await workTask.value
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
                    throw TimeoutError()
                }
                let firstResult = await group.nextResult()!
                continuation.resume(with: firstResult)
            }
        }
    }
}
