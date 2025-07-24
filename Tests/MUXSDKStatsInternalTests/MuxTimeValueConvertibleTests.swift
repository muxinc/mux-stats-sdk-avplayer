import Foundation
import CoreMedia.CMSync
import Testing
@testable import MUXSDKStatsInternal

struct MuxTimeValueConvertibleTests {

    static let validDates = [
        Date(timeIntervalSince1970: 0),
        Date(timeIntervalSinceReferenceDate: 0),
        Date.distantPast,
        Date.distantFuture,
    ]
        .flatMap { (baseDate: Date) -> Array<Date> in
            // Interesting values
            [
                baseDate - 0.001,
                baseDate - 0.0008,
                baseDate - 0.0005, // half millisecond
                baseDate - 0.0003,
                baseDate,
                baseDate + 0.0002,
                baseDate + 0.0005, // half millisecond
                baseDate + 0.0007,
                baseDate + 0.001,
            ]
        }
        .flatMap { (baseDate: Date) -> Array<Date> in
            // Check floating point nonsense
            [
                Date(timeIntervalSinceReferenceDate: baseDate.timeIntervalSinceReferenceDate.nextDown),
                baseDate,
                Date(timeIntervalSinceReferenceDate: baseDate.timeIntervalSinceReferenceDate.nextUp),
            ]
        }

    @Test(arguments: validDates)
    func validDateBehavior(date: Date) throws {
        let muxTimeValue = try #require(date.muxTimeValue)

        #expect(muxTimeValue.int64Value.description == muxTimeValue.stringValue)
        #expect(muxTimeValue.int64Value as NSNumber == muxTimeValue)
    }

    @Test(arguments: [
        (Date(timeIntervalSince1970: 1), Int64(1000) as NSNumber),
        (Date(timeIntervalSince1970: -1), Int64(-1000) as NSNumber),
        (Date(timeIntervalSince1970: 0), Int64(0) as NSNumber),
        (Date(timeIntervalSinceReferenceDate: 0), Int64(NSTimeIntervalSince1970 * 1000) as NSNumber),
        (Date(timeIntervalSince1970: 1_234_567_890.1234), Int64(1_234_567_890_123) as NSNumber),
        (Date(timeIntervalSince1970: 1_234_567_890.12351), Int64(1_234_567_890_124) as NSNumber),
        (Date(timeIntervalSince1970: -1_234_567_890.1234), Int64(-1_234_567_890_123) as NSNumber),
        (Date(timeIntervalSince1970: -1_234_567_890.12351), Int64(-1_234_567_890_124) as NSNumber),
    ])
    func basicDateBehavior(date: Date, expectedValue: NSNumber) throws {
        let muxTimeValue = try #require(date.muxTimeValue)
        #expect(muxTimeValue == expectedValue)
    }

    static let validTimeIntervals = validDates.map(\.timeIntervalSince1970) + [
        .zero,
    ]

    // Set wrapping required due to Xcode 16 bug "Fatal error: Internal inconsistency: No test reporter for test case argumentIDs"
    @Test(arguments: Set(validTimeIntervals))
    func validTimeIntervalBehavior(timeInterval: TimeInterval) throws {
        let muxTimeValue = try #require(timeInterval.muxTimeValue)

        #expect(muxTimeValue.int64Value.description == muxTimeValue.stringValue)
        #expect(muxTimeValue.int64Value as NSNumber == muxTimeValue)
    }

    @Test(arguments: [
        (0.0, Int64(0) as NSNumber),
        (1.123, Int64(1_123) as NSNumber),
        (-1.123, Int64(-1_123) as NSNumber),
        (2.1234, Int64(2_123) as NSNumber),
        (-2.1234, Int64(-2_123) as NSNumber),
        (3.1235, Int64(3_124) as NSNumber),
        (-3.1235, Int64(-3_124) as NSNumber),
        (4.1237, Int64(4_124) as NSNumber),
        (-4.1237, Int64(-4_124) as NSNumber),
    ])
    func basicTimeIntervalBehavior(timeInterval: TimeInterval, expectedValue: NSNumber) throws {
        let muxTimeValue = try #require(timeInterval.muxTimeValue)
        #expect(muxTimeValue == expectedValue)
    }

    @Test(arguments: [
        .nan,
        .infinity,
        -TimeInterval.infinity,
        .greatestFiniteMagnitude,
        -TimeInterval.greatestFiniteMagnitude,
    ])
    func ridiculousTimeIntervals(timeInterval: TimeInterval) throws {
        #expect(timeInterval.muxTimeValue == nil)
        #expect(Date(timeIntervalSince1970: timeInterval).muxTimeValue == nil)
        #expect(Date(timeIntervalSinceReferenceDate: timeInterval).muxTimeValue == nil)
    }

    static let commonTimeScales: [CMTimeScale] = [
        1,
        10,
        24,
        30,
        60,
        1_000,
        8_000,
        16_000,
        90_000,
    ]

    static var validCMTimes: [CMTime] {
        [
            CMTime.zero,
        ]
        +
        validTimeIntervals.flatMap { timeInterval in
            commonTimeScales.map {
                CMTime(seconds: timeInterval, preferredTimescale: $0)
            }
        }
    }

    // Set wrapping required due to Xcode 16 bug "Fatal error: Internal inconsistency: No test reporter for test case argumentIDs"
    @Test(arguments: Set(validCMTimes))
    func validCMTimeBehavior(cmTime: CMTime) throws {
        let muxTimeValue = try #require(cmTime.muxTimeValue)

        #expect(muxTimeValue.int64Value.description == muxTimeValue.stringValue)
        #expect(muxTimeValue.int64Value as NSNumber == muxTimeValue)
    }

    @Test(arguments: [
        CMTime.invalid,
        CMTime.indefinite,
        CMTime.positiveInfinity,
        CMTime.negativeInfinity,
    ])
    func ridiculousCMTimes(cmTime: CMTime) throws {
        #expect(cmTime.muxTimeValue == nil)
    }
}
