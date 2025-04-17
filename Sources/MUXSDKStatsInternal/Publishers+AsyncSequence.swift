import Combine

@available(iOS 13, tvOS 13, *)
extension AsyncSequence {
    var publisher: some Publisher<Element, Error> {
        let subject = PassthroughSubject<Element, Error>()

        let task = Task {
            do {
                for try await event in self {
                    try Task.checkCancellation()
                    subject.send(event)
                }
            } catch {
                subject.send(completion: .failure(error))
                return
            }
            subject.send(completion: .finished)
        }

        return subject
            .handleEvents(receiveCancel: {
                task.cancel()
            })
    }
}
