import Combine

@available(iOS 13, tvOS 13, *)
extension Future where Failure == Never {
    convenience init(isolation: isolated (any Actor)? = #isolation, operation: @escaping () async -> sending Output) {
        self.init { promise in
            Task {
                _ = isolation
                promise(.success(await operation()))
            }
        }
    }
}
