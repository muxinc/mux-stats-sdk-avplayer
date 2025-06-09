import Dispatch

private let mainQueueKey = {
  let key = DispatchSpecificKey<Void>()
  DispatchQueue.main.setSpecific(key: key, value: ())
  return key
}()

extension DispatchQueue {
    static var isMainQueue: Bool {
        DispatchQueue.getSpecific(key: mainQueueKey) != nil
    }
}

