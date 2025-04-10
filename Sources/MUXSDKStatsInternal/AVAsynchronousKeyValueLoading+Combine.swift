import AVFoundation
import Combine

@available(iOS 15, tvOS 15, *)
extension AVAsynchronousKeyValueLoading {
    func future<T>(for property: AVAsyncProperty<Self, T>) -> Future<T, Error> {
        Future { promise in
            Task.detached(priority: Task.currentPriority) {
                do {
                    promise(.success(try await self.load(property)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}
