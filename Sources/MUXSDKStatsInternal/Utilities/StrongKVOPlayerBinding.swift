import Foundation
import AVKit

@objc(MUXSDKStrongKVOPlayerVCBinding)
public final class StrongKVOPlayerVCBinding: NSObject, Sendable {
    @MainActor
    private var observation: NSKeyValueObservation?

    @objc public let playerViewController: AVPlayerViewController

    @objc public init(playerViewController: AVPlayerViewController,
                      onPlayerChange: @Sendable @escaping (AVPlayer?) -> Void) {
        self.playerViewController = playerViewController
        super.init()

        let startObserving = { @MainActor [weak self] in
            guard let self else {
                return
            }
            self.observation = playerViewController.observe(\.player, options: [.initial, .new]) { _, change in
                onPlayerChange(change.newValue!)
            }
        }

        guard #available(iOS 13, tvOS 13, *) else {
            DispatchQueue.main.async(execute: startObserving)
            return
        }

        if DispatchQueue.isMainQueue {
            MainActor.assumeIsolated {
                startObserving()
            }
        } else {
            Task { @MainActor in
                startObserving()
            }
        }
    }
}

@objc(MUXSDKStrongKVOPlayerLayerBinding)
public final class StrongKVOPlayerLayerBinding: NSObject {
    private let observation: NSKeyValueObservation

    @objc public let playerLayer: AVPlayerLayer

    @objc public init(playerLayer: AVPlayerLayer,
                      onPlayerChange: @Sendable @escaping (AVPlayer?) -> Void) {
        self.playerLayer = playerLayer
        observation = playerLayer.observe(\.player, options: [.initial, .new]) { _, change in
            onPlayerChange(change.newValue!)
        }
    }
}
