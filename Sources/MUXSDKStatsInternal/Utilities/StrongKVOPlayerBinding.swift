import Foundation
import AVKit

@objc(MUXSDKStrongKVOPlayerVCBinding)
public final class StrongKVOPlayerVCBinding: NSObject {
    private var observation: NSKeyValueObservation?
    @objc private(set) public var playerViewController: AVPlayerViewController?

    @MainActor
    @objc public init(playerViewController: AVPlayerViewController, onPlayerChange: @Sendable @escaping (AVPlayer?) -> Void) {
        observation = playerViewController.observe(\.player, options: [.initial, .new]) { _, change in
            onPlayerChange(change.newValue!)
        }
        self.playerViewController = playerViewController
    }
}

@objc(MUXSDKStrongKVOPlayerLayerBinding)
public final class StrongKVOPlayerLayerBinding: NSObject {
    private var observation: NSKeyValueObservation?
    @objc private(set) public var playerLayer: AVPlayerLayer?

    @objc public init(playerLayer: AVPlayerLayer, onPlayerChange: @Sendable @escaping (AVPlayer?) -> Void) {
        observation = playerLayer.observe(\.player, options: [.initial, .new]) { _, change in
            onPlayerChange(change.newValue!)
        }
        self.playerLayer = playerLayer
    }
}
