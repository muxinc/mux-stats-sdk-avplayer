import Combine

@available(iOS 13, tvOS 13, *)
extension Future where Failure == Never {
    convenience init(isolation: isolated (any Actor)? = #isolation, priority: TaskPriority? = nil, operation: @escaping () async -> sending Output) {
        self.init { promise in
            Task(priority: priority) {
                _ = isolation
                promise(.success(await operation()))
            }
        }
    }
}
