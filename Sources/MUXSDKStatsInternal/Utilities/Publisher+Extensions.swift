import Combine

@available(iOS 14, tvOS 14, *)
extension Publisher {

    /// Transforms all elements from the upstream publisher with a provided async closure, waiting for completion before advancing to the next element.
    func mapSerial<T>(isolation: isolated (any Actor)? = #isolation, priority: TaskPriority? = nil, _ transform: @escaping (Self.Output) async -> sending T) -> some Publisher<T, Failure> {
        flatMap(maxPublishers: .max(1)) { value in
            Future(isolation: isolation, priority: priority) {
                await transform(value)
            }
        }
    }
}

@available(iOS 13, tvOS 13, *)
extension Publisher {

    /// Transforms all elements on the main queue.
    ///
    /// MuxCore objects are not thread-safe. Event pipelines finish their asynchronous work on
    /// Sendable values, then create MuxCore objects here so they never leave the main queue.
    func mapOnMainQueue<T>(_ transform: @escaping (Self.Output) -> T) -> some Publisher<T, Failure> {
        receive(on: ImmediateIfOnMainQueueScheduler.shared)
            .map(transform)
    }
}
