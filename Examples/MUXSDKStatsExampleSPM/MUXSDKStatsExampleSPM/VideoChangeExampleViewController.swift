//
//  VideoChangeExampleViewController.swift
//  MUXSDKStatsExampleSPM
//

import UIKit
import MUXSDKStats

/// Demonstrates manually switching an AVPlayer to a new item and
/// using videoChange to mark the new logical video context.
class VideoChangeExampleViewController: UIViewController {
    let playerName = "VideoChangeExample"
    let playbackURLs: [URL] = [
        URL(
            string: "https://stream.mux.com/00ezSo01tK00mfbBKDLUtKnwVsUKF2y5cjBMvJwBh5Z0202g.m3u8"
        )!,
        URL(
            string: "https://stream.mux.com/u02xH9SB1ZZNNjPiQp4l6mhzBKJ101uExYx4LU02J5Xm88.m3u8"
        )!,
    ]
    lazy var playerViewController = AVPlayerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Step 1: Create your AVPlayer and assign it to AVPlayerViewController.
        let firstItem = AVPlayerItem(url: playbackURLs[0])
        let player = AVPlayer(playerItem: firstItem)
        playerViewController.player = player

        // Step 2: Build Mux customer metadata.
        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoTitle = "First Test Video"
        videoData.videoId = "VideoChangeExample-FirstTestVideo"

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
        setupPlayerItemObserver(firstItem: firstItem)

        // Step 5: Present the player UI and start playback.
        displayPlayerViewController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerViewController.player?.play()
    }

    func setupPlayerItemObserver(firstItem: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayerItemDidPlayToEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: firstItem
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
        videoData.videoTitle = "Second Test Video"
        videoData.videoId = "VideoChangeExample-SecondTestVideo"

        let customData = MUXSDKCustomData()
        customData.customData1 = "VideoChangeExample"
        customData.customData2 = "VideoChange-SecondTestVideo"

        let customerData = MUXSDKCustomerData()
        customerData.customerVideoData = videoData
        customerData.customData = customData

        MUXSDKStats.videoChange(
            forPlayer: playerName,
            with: customerData
        )

        let secondItem = AVPlayerItem(url: playbackURLs[1])
        playerViewController.player?.replaceCurrentItem(with: secondItem)
        playerViewController.player?.play()
    }

    deinit {
        // Step 6: When done with this AVPlayer instance, call destroyPlayer to remove observers.
        playerViewController.player?.pause()
        MUXSDKStats.destroyPlayer(playerName)
    }
}
