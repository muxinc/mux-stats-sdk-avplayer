//
//  AVQueuePlayerExampleViewController.swift
//  MUXSDKStatsExampleSPM
//

import UIKit
import MUXSDKStats

/// Demonstrates monitoring an AVQueuePlayer and dispatching videoChange
/// when playback advances to the next queued item.
class AVQueuePlayerExampleViewController: UIViewController {
    let playerName = "AVQueuePlayerExample"
    let playerItems: [AVPlayerItem] = [
        AVPlayerItem(
            url: URL(
                string: "https://stream.mux.com/00ezSo01tK00mfbBKDLUtKnwVsUKF2y5cjBMvJwBh5Z0202g.m3u8"
            )!
        ),
        AVPlayerItem(
            url: URL(
                string: "https://stream.mux.com/u02xH9SB1ZZNNjPiQp4l6mhzBKJ101uExYx4LU02J5Xm88.m3u8"
            )!
        )
    ]
    lazy var playerViewController = AVPlayerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Step 1: Create your AVQueuePlayer and assign it to AVPlayerViewController.
        let player = AVQueuePlayer(items: playerItems)
        playerViewController.player = player

        // Step 2: Build Mux customer metadata.
        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoTitle = "First Test Video in Queue"
        videoData.videoId = "AVQueuePlayerExample-FirstTestVideo"

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

        // Step 4: Add playback observers.
        setupPlayerItemObserver()

        // Step 5: Present the player UI and start playback.
        displayPlayerViewController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerViewController.player?.play()
    }

    func setupPlayerItemObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayerItemDidPlayToEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItems.first
        )
    }

    func displayPlayerViewController() {
        addChild(playerViewController)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerViewController.view)
        view.addConstraints([
            view.topAnchor.constraint(equalTo: playerViewController.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: playerViewController.view.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: playerViewController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: playerViewController.view.trailingAnchor),
        ])
        playerViewController.didMove(toParent: self)
    }

    @objc func handlePlayerItemDidPlayToEnd(_ notification: Notification) {
        let videoData = MUXSDKCustomerVideoData()
        videoData.videoTitle = "Second Test Video in Queue"
        videoData.videoId = "AVQueuePlayerExample-SecondTestVideo"

        let customerData = MUXSDKCustomerData()
        customerData.customerVideoData = videoData

        MUXSDKStats.videoChange(
            forPlayer: playerName,
            with: customerData
        )
    }

    deinit {
        // Step 6: When done with this AVPlayer instance, call destroyPlayer to remove observers.
        playerViewController.player?.pause()
        MUXSDKStats.destroyPlayer(playerName)
    }
}
