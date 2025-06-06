import Foundation

struct TimeoutError: Error {
}

@available(iOS 13, tvOS 13, *)
func withTimeout<Output>(of seconds: TimeInterval, operation: sending @escaping @isolated(any) () async throws -> Output) async throws -> Output {
    try await withThrowingTaskGroup(of: Output.self) { group in
        group.addTask(operation: operation)
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
            throw TimeoutError()
        }

        defer {
            group.cancelAll()
        }

        return try await group.nextResult()!.get()
    }
}
