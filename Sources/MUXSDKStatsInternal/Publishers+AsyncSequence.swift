import Combine

@available(iOS 18, tvOS 18, *)
extension AsyncSequence {
    var publisher: some Publisher<Element, Failure> {
        let subject = PassthroughSubject<Element, Failure>()

        let task = Task<Void, Never> {
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
