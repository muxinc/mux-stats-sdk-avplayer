import Combine

@available(iOS 14, tvOS 14, *)
extension Publisher {
    func map<T>(isolation: isolated (any Actor)? = #isolation, priority: TaskPriority? = nil, _ transform: @escaping (Self.Output) async -> sending T) -> some Publisher<T, Failure> {
        flatMap { value in
            Future(isolation: isolation, priority: priority) {
                await transform(value)
            }
        }
    }
}
