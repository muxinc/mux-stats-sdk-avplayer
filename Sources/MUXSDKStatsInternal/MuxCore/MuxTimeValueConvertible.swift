import CoreMedia.CMSync
import Foundation

protocol MuxTimeValueConvertible {
    var muxTimeValue: NSNumber? { get }
}

@available(iOS 13, tvOS 13, *)
extension Measurement: MuxTimeValueConvertible where UnitType == UnitDuration {
    var muxTimeValue: NSNumber? {
        let milliseconds = converted(to: .milliseconds)
            .value
            .rounded(.toNearestOrAwayFromZero)

        guard milliseconds.isFinite, let msCount = Int64(exactly: milliseconds) else {
            return nil
        }

        return msCount as NSNumber
    }
}

@available(iOS 13, tvOS 13, *)
extension TimeInterval: MuxTimeValueConvertible {
    var muxTimeValue: NSNumber? {
        Measurement(value: self, unit: UnitDuration.seconds)
            .muxTimeValue
    }
}

@available(iOS 13, tvOS 13, *)
extension Date: MuxTimeValueConvertible {
    var muxTimeValue: NSNumber? {
        timeIntervalSince1970.muxTimeValue
    }
}

@available(iOS 13, tvOS 13, *)
extension CMTime: MuxTimeValueConvertible {
    var muxTimeValue: NSNumber? {
        seconds.muxTimeValue
    }
}
