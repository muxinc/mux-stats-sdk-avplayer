//
//  PlayerLayerExampleViewController.swift
//  MUXSDKStatsExampleSPM
//

import UIKit
import MUXSDKStats

/// UIView container for AVPlayerLayer
class PlayerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var player: AVPlayer? {
        get {
            (layer as? AVPlayerLayer)?.player
        }
        set {
            (layer as? AVPlayerLayer)?.player = newValue
        }
    }
}

/// Bare bones AVPlayerLayer example without controls or
/// other affordances
class PlayerLayerExampleViewController: UIViewController {

    var playbackURL: URL {
        let playbackID = ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"

        return URL(
            string: "https://stream.mux.com/\(playbackID).m3u8"
        )!
    }
    let playerName = "AVPlayerLayerExample"
    lazy var playerView = PlayerView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Step 1: Create your AVPlayer and assign it to the AVPlayerLayer-backed view.
        playerView.player = AVPlayer(url: playbackURL)

        // Step 2: Build Mux customer metadata.
        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoId = "AVPlayerLayerPlaybackExample"
        videoData.videoTitle = "Video Behind the Scenes"

        guard let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData,
            videoData: videoData,
            viewData: nil
        ) else {
            return
        }

        guard let playerLayer = playerView.layer as? AVPlayerLayer else {
            return
        }

        // Step 3: Start monitoring this AVPlayerLayer with a stable player name.
        MUXSDKStats.monitorAVPlayerLayer(
            playerLayer,
            withPlayerName: playerName,
            customerData: customerData
        )

        // Step 4: Present the player UI and start playback.
        displayPlayerView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView.player?.play()
    }

    func displayPlayerView() {
        playerView.backgroundColor = .black
        playerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerView)
        view.addConstraints([
            view.leadingAnchor.constraint(
                equalTo: playerView.leadingAnchor
            ),
            view.trailingAnchor.constraint(
                equalTo: playerView.trailingAnchor
            ),
            view.topAnchor.constraint(
                equalTo: playerView.topAnchor
            ),
            view.bottomAnchor.constraint(
                equalTo: playerView.bottomAnchor
            ),
        ])
    }

    deinit {
        // Step 5: When done with this AVPlayer instance, call destroyPlayer to remove observers.
        playerView.player?.pause()
        MUXSDKStats.destroyPlayer(playerName)
    }
}
