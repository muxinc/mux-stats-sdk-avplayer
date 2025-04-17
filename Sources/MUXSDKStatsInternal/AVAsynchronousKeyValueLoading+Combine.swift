import AVFoundation
import Combine

@available(iOS 15, tvOS 15, *)
extension AVAsynchronousKeyValueLoading {
    func future<T>(for property: AVAsyncProperty<Self, T>) -> Future<T, Error> {
        Future { promise in
            if case let .loaded(value) = self.status(of: property) {
                promise(.success(value))
                return
            }
            Task {
                do {
                    promise(.success(try await self.load(property)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}
