//
//  PlayerLayerScalingExampleViewController.swift
//  MUXSDKStatsExampleSPM
//

import AVFoundation
import AVKit
import UIKit

import MuxCore
import MUXSDKStats

class PlayerLayerScalingExampleViewController: UIViewController {
    var playbackURL: URL {
        let playbackID = ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"

        return URL(
            string: "https://stream.mux.com/\(playbackID).m3u8"
        )!
    }
    let playerName = "AVPlayerLayerScalingExample"

    lazy var playerView = PlayerView()

    override func viewDidLoad() {
        super.viewDidLoad()

        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoId = "VideoBehindTheScenes"
        videoData.videoTitle = "Video Behind the Scenes"

        let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData,
            videoData: videoData,
            viewData: nil
        )!

        playerView.backgroundColor = .black

        playerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerView)
        view.addConstraints([
            view.centerXAnchor.constraint(
                equalTo: playerView.centerXAnchor
            ),
            view.centerYAnchor.constraint(
                equalTo: playerView.centerYAnchor
            ),
            view.widthAnchor.constraint(
                equalTo: playerView.widthAnchor,
                multiplier: 1.0
            ),
            view.heightAnchor.constraint(
                equalTo: playerView.heightAnchor,
                multiplier: 0.5
            ),
        ])

        playerView.player = AVPlayer(
            url: playbackURL
        )

        guard let playerLayer = playerView.layer as? AVPlayerLayer else {
            return
        }

        MUXSDKMonitor.shared().startMonitoringPlayerLayer(
            playerLayer,
            withPlayerName: playerName,
            customerData: customerData
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView.player?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        MUXSDKMonitor.shared().stopMonitoring(
            withPlayerName: playerName
        )
        playerView.player?.pause()
        super.viewWillDisappear(animated)
    }
}
