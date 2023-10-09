//
//  MultiplePlayerItemPlaybackExampleViewController.swift
//  MUXSDKStatsExampleSPM
//

import AVKit
import UIKit

import MUXSDKStats

class AVQueuePlayerExampleViewController: MultiplePlayerItemPlaybackExampleViewController {

    override var playerName: String {
        return "AVQueuePlayerExample"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let player = AVQueuePlayer(
            items: playerItems
        )

        self.playerViewController.player = player
    }
}

class VideoChangeExampleViewController: MultiplePlayerItemPlaybackExampleViewController {

    override var playerName: String {
        return "VideoChangeExample"
    }

    override func handlePlayerItemDidPlayToEnd(_ notification: Notification) {
        let videoData = MUXSDKCustomerVideoData()
        videoData.videoTitle = "Second Test Video in Queue"
        videoData.videoTitle = "SecondTestVideo"

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
    }
}

class MultiplePlayerItemPlaybackExampleViewController: UIViewController {
    var playerItems: [AVPlayerItem] = [
        AVPlayerItem(
            url: URL(
                string: "https://stream.mux.com/qIy2uu9BfvomNnH02hFPysxeXvL6FkFXs63wTqnEiaYs.m3u8"
            )!
        ),
        AVPlayerItem(
            url: URL(
                string: "https://stream.mux.com/7Tqs5u3MoQhGOk7XoyT81bjoPFFkOPQIH32Pt4XDbyQ.m3u8"
            )!
        )
    ]

    var playerName: String {
        return "AVQueuePlayerExample"
    }
    lazy var playerViewController = AVPlayerViewController()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayerItemDidPlayToEnd),
            name: Notification.Name.AVPlayerItemDidPlayToEndTime,
            object: playerItems[0]
        )

        let player = AVPlayer(
            playerItem: playerItems[0]
        )

        playerViewController.player = player
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        displayPlayerViewController()

        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoTitle = "First Test Video in Queue"
        videoData.videoTitle = "FirstTestVideo"

        let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData,
            videoData: nil,
            viewData: nil
        )

        MUXSDKStats.monitorAVPlayerViewController(
            playerViewController,
            withPlayerName: playerName,
            customerData: customerData!
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        playerViewController.player?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        MUXSDKStats.destroyPlayer(
            playerName
        )

        super.viewWillDisappear(animated)
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

    func hidePlayerViewController() {
        playerViewController.willMove(toParent: nil)
        playerViewController.view.removeFromSuperview()
        playerViewController.removeFromParent()
    }

    @objc func handlePlayerItemDidPlayToEnd(
        _ notification: Notification
    ) {
        let videoData = MUXSDKCustomerVideoData()
        videoData.videoTitle = "Second Test Video in Queue"
        videoData.videoTitle = "SecondTestVideo"

        let customerData = MUXSDKCustomerData()
        customerData.customerVideoData = videoData

        MUXSDKStats.videoChange(
            forPlayer: playerName,
            with: customerData
        )
    }
}
