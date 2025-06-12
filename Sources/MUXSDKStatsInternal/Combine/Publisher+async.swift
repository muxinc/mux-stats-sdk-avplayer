//
//  Publisher+async.swift
//  MUXSDKStats
//
//  Created by Kevin Cassidy on 6/11/25.
//

import Combine

// no effect on Failure type
@available(iOS 14, tvOS 14, *)
extension Publisher {
    // non-throwing
    func map<T>(_ transform: @escaping (Output) async -> sending T) -> some Publisher<T, Failure> {
        flatMap(maxPublishers: .max(1)) { output in
            Future {
                await transform(output)
            }
        }
    }

    // throwing
    func tryMap<T>(_ transform: @escaping (Output) async throws(Failure) -> sending T) -> some Publisher<T, Failure> {
        flatMap(maxPublishers: .max(1)) { output in
            Future { () async throws(Failure) -> T in
                try await transform(output)
            }
        }
    }
}

@available(iOS 14, tvOS 14, *)
extension Publisher {
    // throw any Error
    func tryMap<T>(_ transform: @escaping (Output) async throws -> sending T) -> some Publisher<T, Error> {
        mapError { $0 as Error }
            .tryMap(transform)
    }
}

@available(iOS 14, tvOS 14, *)
extension Publisher where Failure == Never {
    // set the Failure type based on thrown Error
    func tryMap<T, E>(_ transform: @escaping (Output) async throws(E) -> sending T) -> some Publisher<T, E> {
        setFailureType(to: E.self)
            .tryMap(transform)
    }
}
