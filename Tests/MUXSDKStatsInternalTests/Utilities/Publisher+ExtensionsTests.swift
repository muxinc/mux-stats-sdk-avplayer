import Combine
import Foundation
import Testing
@testable import MUXSDKStatsInternal

struct PublisherExtensionsTests {

    // MARK: - Basic Transformation

    @available(iOS 14, tvOS 14, *)
    @Test func testMapTransformsSingleValue() async throws {
        try await confirmation(expectedCount: 1) { confirmation in
            let values = try await collectOutput(
                from: Just(1).map { value async in
                    confirmation()
                    return value * 2
                }
            )
            #expect(values == [2])
        }
    }

    @available(iOS 14, tvOS 14, *)
    @Test func testMapTransformsMultipleValues() async throws {
        try await confirmation(expectedCount: 3) { confirmation in
            let values = try await collectOutput(
                from: [1, 2, 3].publisher.map { value async in
                    confirmation()
                    return value * 10
                }
            )
            #expect(values == [10, 20, 30])
        }
    }

    @available(iOS 14, tvOS 14, *)
    @Test func testMapWithAsyncDelayedTransform() async throws {
        let values = try await collectOutput(
            from: [1, 2, 3].publisher.map { value async in
                try? await Task.sleep(nanoseconds: UInt64(NSEC_PER_MSEC * 10))
                return value + 100
            }
        )
        #expect(values == [101, 102, 103])
    }

    // MARK: - Type Transformation

    @available(iOS 14, tvOS 14, *)
    @Test func testMapChangesOutputType() async throws {
        let values = try await collectOutput(
            from: Just(42).map { value async in
                "\(value)"
            }
        )
        #expect(values == ["42"])
    }

    // MARK: - Ordering

    @available(iOS 14, tvOS 14, *)
    @Test func testMapPreservesSequentialOrder() async throws {
        var order: [Int] = []
        let values = try await collectOutput(
            from: [1, 2, 3, 4, 5].publisher.map { value async in
                // Vary delays inversely to ensure ordering
                // is maintained by serial execution, not speed
                let delay = UInt64(NSEC_PER_MSEC) * UInt64((6 - value) * 5)
                try? await Task.sleep(nanoseconds: delay)
                order.append(value)
                return value
            }
        )
        #expect(values == [1, 2, 3, 4, 5])
        #expect(order == [1, 2, 3, 4, 5])
    }

    // MARK: - Empty Publisher

    @available(iOS 14, tvOS 14, *)
    @Test func testMapWithEmptyPublisher() async throws {
        try await confirmation(expectedCount: 0) { confirmation in
            let values = try await collectOutput(
                from: Empty<Int, Never>().map { value async in
                    confirmation()
                    return "\(value)"
                }
            )
            #expect(values.isEmpty)
        }
    }

    // MARK: - Helper

    private func collectOutput<P: Publisher>(
        from publisher: P,
        timeout: TimeInterval = 5.0
    ) async throws -> [P.Output] where P.Failure == Never, P.Output: Sendable {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var values: [P.Output] = []
            let queue = DispatchQueue(label: "collect output helper", target: .global())

            cancellable = publisher
                .setFailureType(to: TimeoutError.self)
                .timeout(.seconds(timeout), scheduler: queue, customError: { TimeoutError() })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            continuation.resume(returning: values)
                        case .failure(let failure):
                            continuation.resume(throwing: failure)
                        }
                        _ = cancellable
                        _ = queue
                    },
                    receiveValue: { value in
                        values.append(value)
                    }
                )
        }
    }
}
