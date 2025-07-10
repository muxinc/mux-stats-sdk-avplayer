//
//  AVPlayer+Helpers.swift
//  IntegrationTests
//
//  Created by Santiago Puppo on 9/7/25.
//
import Combine


enum PlayerPlaybackError: Error {
    case failedToPlay
    case itemFailed(Error?, AVPlayerItemErrorLog?)
    case noPlayerItem
    case timeout
    case unknown
}

public func waitForPlaybackToStart(
    with player: AVPlayer,
    for playerName: String,
    timeout: TimeInterval = 60.0
) async throws {
    var cancellables = [AnyCancellable]()
    let startTime = Date()
    
    debugPrint("\(startTime) - \(playerName) - Waiting for playback to start... ")
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) -> Void in
        guard let item = player.currentItem else {
            continuation.resume(throwing: PlayerPlaybackError.noPlayerItem)
            return
        }
        
        let observer : AnyPublisher<Result<Void, PlayerPlaybackError>, Never> = item
            .publisher(for: \.status)
            .filter { $0 != .unknown } // We filter unkown to not throw unwanted PlayerPlaybackError.unknown
            .tryMap { [weak item] status in
                guard let item else {
                    throw PlayerPlaybackError.noPlayerItem
                }
                
                switch status {
                case .readyToPlay:
                    return
                case .failed:
                    throw PlayerPlaybackError.itemFailed(item.error, item.errorLog())
                default:
                    throw PlayerPlaybackError.unknown
                }
            }
            .timeout(
                .seconds(timeout),
                scheduler: DispatchQueue.main,
                customError: { PlayerPlaybackError.timeout as Error }
            )
            .map { _ in Result.success(())}
            .catch { error in
                let error = error as? PlayerPlaybackError ?? PlayerPlaybackError.unknown
                return Just(Result.failure(error) as Result<Void, PlayerPlaybackError>)
            }
            .eraseToAnyPublisher()
        
        cancellables.append(observer
            .sink { result in
                let endTime = Date()
                let seconds = endTime.timeIntervalSince(startTime)
                switch result {
                case .success():
                    print("## Playback started in \(seconds) seconds")
                    continuation.resume()
                case .failure(let error):
                    print("## Playback Failed: \(error) in \(seconds) seconds (Timeout: \(timeout))")
                    let error = error as PlayerPlaybackError
                    continuation.resume(throwing: error)
                }
            })
    }
    }
