//
//  BasicPlaybackExampleViewController.swift
//  MUXSDKStatsExampleSPM
//

import UIKit
import MUXSDKStats

class BasicPlaybackExampleViewController: UIViewController {

    var playbackURL: URL {
        let playbackID = ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"

        return URL(
            string: "https://stream.mux.com/\(playbackID).m3u8"
        )!
    }
    let playerName = "AVPlayerViewControllerExample"
    lazy var playerViewController = AVPlayerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Step 1: Create your AVPlayer and assign it to AVPlayerViewController.
        let player = AVPlayer(url: playbackURL)
        playerViewController.player = player

        // Step 2: Build Mux customer metadata.
        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoId = "BasicPlaybackAVPlayerViewControllerExample"
        videoData.videoTitle = "Video Behind the Scenes"

        guard let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData,
            videoData: videoData,
            viewData: nil
        ) else {
            return
        }

        // Step 3: Start monitoring this player view controller with a stable player name.
        MUXSDKStats.monitorAVPlayerViewController(
            playerViewController,
            withPlayerName: playerName,
            customerData: customerData
        )

        // Step 4: Present the player UI and start playback.
        displayPlayerViewController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerViewController.player?.play()
    }

    func displayPlayerViewController() {
        self.addChild(playerViewController)
        playerViewController.view
            .translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(playerViewController.view)
        self.view.addConstraints([
            self.view.topAnchor.constraint(
                equalTo: playerViewController.view.topAnchor
            ),
            self.view.bottomAnchor.constraint(
                equalTo: playerViewController.view.bottomAnchor
            ),
            self.view.leadingAnchor.constraint(
                equalTo: playerViewController.view.leadingAnchor
            ),
            self.view.trailingAnchor.constraint(
                equalTo: playerViewController.view.trailingAnchor
            )
        ])
        playerViewController.didMove(toParent:self)
    }

    deinit {
        // Step 5: When done with this AVPlayer instance, call destroyPlayer to remove observers.
        playerViewController.player?.pause()
        MUXSDKStats.destroyPlayer(playerName)
    }
}
