import Combine

@available(iOS 18, tvOS 18, visionOS 2, *)
extension AsyncSequence where Self: Sendable {
    var publisher: some Publisher<Element, Failure> {
        Deferred {
            publishedImmediately()
        }
    }

    func publishedImmediately(isolation: isolated (any Actor)? = #isolation) -> some Publisher<Element, Failure> {
        let subject = PassthroughSubject<Element, Failure>()

        let task = Task<Void, Never> {
            _ = isolation
            do throws(Failure) {
                for try await element in self {
                    if Task.isCancelled {
                        break
                    }
                    subject.send(element)
                }
                subject.send(completion: .finished)
            } catch {
                subject.send(completion: .failure(error))
            }
        }

        return subject
            .handleEvents(receiveCancel: {
                task.cancel()
            })
    }
}
