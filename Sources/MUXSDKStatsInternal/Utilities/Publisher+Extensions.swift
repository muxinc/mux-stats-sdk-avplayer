import Combine

@available(iOS 14, tvOS 14, *)
extension Publisher {

    /// Transforms all elements from the upstream publisher with a provided async closure, waiting for completion before advancing to the next element.
    func map<T>(isolation: isolated (any Actor)? = #isolation, priority: TaskPriority? = nil, _ transform: @escaping (Self.Output) async -> sending T) -> some Publisher<T, Failure> {
        flatMap(maxPublishers: .max(1)) { value in
            Future(isolation: isolation, priority: priority) {
                await transform(value)
            }
        }
    }
}
