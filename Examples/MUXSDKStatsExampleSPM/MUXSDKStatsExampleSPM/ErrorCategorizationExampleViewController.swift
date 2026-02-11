//
//  ErrorCategorizationExampleViewController.swift
//  MUXSDKStatsExampleSPM
//

import AVFoundation
import AVKit
import UIKit
import MUXSDKStats
import MuxCore

class ErrorCategorizationExampleViewController: UIViewController {
    var playbackURL: URL {
        let playbackID = ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"

        return URL(
            string: "https://stream.mux.com/\(playbackID).m3u8"
        )!
    }
    let playerName = "ErrorCategorizationExample"
    lazy var player = AVPlayer(url: playbackURL)
    lazy var playerViewController = AVPlayerViewController()

    deinit {
        playerViewController.player?.pause()
        MUXSDKStats.destroyPlayer(playerName)
    }

    override var childForStatusBarStyle: UIViewController? {
        playerViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoId = "ErrorCategorizationExample"
        videoData.videoTitle = "Video Behind the Scenes"

        let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData,
            videoData: videoData,
            viewData: nil
        )

        let player = AVPlayer(url: playbackURL)
        playerViewController.player = player

        displayPlayerViewController()

        MUXSDKStats.monitorAVPlayerViewController(
            playerViewController,
            withPlayerName: playerName,
            customerData: customerData!
        )

        let errorSubmissionsMenu = UIMenu(
            title: "Submit Errors",
            children: [
                UIAction(
                    title: "Submit Playback Error with Fatal Severity",
                    handler: { [weak self] _ in
                        guard let self else { return }
                        MUXSDKStats.dispatchError(
                            "123",
                            withMessage: "Playback Error with Fatal Severity: Manually Dispatched",
                            forPlayer: self.playerName
                        )
                    }
                ),
                UIAction(
                    title: "Submit Playback Error with Warning Severity",
                    handler: { [weak self] _ in
                        guard let self else { return }
                        MUXSDKStats.dispatchError(
                            "456",
                            withMessage: "Playback Error with Warning Severity: Manually Dispatched",
                            severity: MUXSDKErrorSeverity.warning,
                            forPlayer: self.playerName
                        )
                    }
                ),
                UIAction(
                    title: "Submit Business Exception Error with Fatal Severity",
                    handler: { [weak self] _ in
                        guard let self else { return }
                        MUXSDKStats.dispatchError(
                            "789",
                            withMessage: "Business Exception Error with Fatal Severity: Manually Dispatched",
                            severity: MUXSDKErrorSeverity.fatal,
                            isBusinessException: true,
                            forPlayer: self.playerName
                        )
                    }
                ),
                UIAction(
                    title: "Submit Business Exception Error with Warning Severity",
                    handler: { [weak self] _ in
                        guard let self else { return }
                        MUXSDKStats.dispatchError(
                            "012",
                            withMessage: "Business Exception Error with Warning Severity: Manually Dispatched",
                            severity: MUXSDKErrorSeverity.warning,
                            isBusinessException: true,
                            forPlayer: self.playerName
                        )
                    }
                ),
            ]
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Submit Errors",
            menu: errorSubmissionsMenu
        )
    }

    func displayPlayerViewController() {
        playerViewController.willMove(toParent:self)
        self.addChild(playerViewController)
        playerViewController.view
            .translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(playerViewController.view)
        self.view.addConstraints([
            self.view.topAnchor.constraint(
                equalTo: playerViewController.view.safeAreaLayoutGuide.topAnchor
            ),
            self.view.bottomAnchor.constraint(
                equalTo: playerViewController.view.safeAreaLayoutGuide.bottomAnchor
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        playerViewController.player?.play()
    }
}
