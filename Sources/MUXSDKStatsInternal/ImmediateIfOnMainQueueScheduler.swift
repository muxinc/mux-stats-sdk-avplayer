import Combine
import Dispatch

@available(iOS 13, tvOS 13, *)
struct ImmediateIfOnMainQueueScheduler : Scheduler {
    typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
    typealias SchedulerOptions = Never

    static let shared = Self()

    private init() {
    }

    var now: SchedulerTimeType {
        DispatchQueue.main.now
    }

    var minimumTolerance: SchedulerTimeType.Stride {
        DispatchQueue.main.minimumTolerance
    }

    func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        if DispatchQueue.isMainQueue {
            ImmediateScheduler.shared.schedule(options: options, action)
        } else {
            DispatchQueue.main.schedule(options: nil, action)
        }
    }

    func schedule(after date: DispatchQueue.SchedulerTimeType, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
        DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: nil, action)
    }

    func schedule(after date: DispatchQueue.SchedulerTimeType, interval: SchedulerTimeType.Stride, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) -> any Cancellable {
        DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, action)
    }
}
