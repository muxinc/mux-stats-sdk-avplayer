import Combine

@available(iOS 13, tvOS 13, *)
extension Future where Failure == Never {
    convenience init(priority: TaskPriority? = nil, operation: sending @escaping @isolated(any) () async -> Output) {
        self.init { promise in
            Task(priority: priority) {
                promise(.success(await operation()))
            }
        }
    }
}
