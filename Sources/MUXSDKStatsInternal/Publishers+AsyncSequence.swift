import Combine

@available(iOS 13, tvOS 13, *)
extension AsyncSequence {
    var publisher: some Publisher<Element, Error> {
        let subject = PassthroughSubject<Element, Error>()

        let task = Task {
            do {
                for try await event in self {
                    if Task.isCancelled {
                        break
                    }
                    subject.send(event)
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
