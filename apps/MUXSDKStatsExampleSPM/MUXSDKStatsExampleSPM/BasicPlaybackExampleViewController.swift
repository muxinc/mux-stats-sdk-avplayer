//
//  ViewController.swift
//  MUXSDKStatsExampleSPM
//

import UIKit
import AVKit
import MUXSDKStats

class BasicPlaybackExampleViewController: UIViewController {

    var playbackURL: URL {
        let playbackID = ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"

        return URL(
            string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
        )!

//        return URL(
//            string: "https://stream.mux.com/\(playbackID).m3u8"
//        )!
    }
    let playerName = "AVPlayerViewControllerExample"
    lazy var playerViewController = AVPlayerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoId = "TimeUpdateErrorDimensionTest"
        videoData.videoTitle = "Video Behind the Scenes"

        let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData,
            videoData: videoData,
            viewData: nil
        )

        let player = AVPlayer(url: playbackURL)
        playerViewController.player = player
        playerViewController.delegate = self
        playerViewController.allowsPictureInPicturePlayback = false

        displayPlayerViewController()

        MUXSDKStats.monitorAVPlayerViewController(
            playerViewController,
            withPlayerName: playerName,
            customerData: customerData!
        )

//        DispatchQueue.main.asyncAfter(
//            deadline: .now() + 20,
//            execute: {
//
//                MUXSDKStats.dispatchError(
//                    "123",
//                    withMessage: "This is a test error",
//                    forPlayer: self.playerName
//                )
//            }
//        )

//        DispatchQueue.main.asyncAfter(
//            deadline: .now() + 25,
//            execute: {
//                let timeUpdateEvent = MUXSDKTimeUpdateEvent()
//                let playerData = MUXSDKPlayerData()
//                playerData.playerMuxPluginName = "apple-mux"
//                playerData.playerMuxPluginVersion = "3.6.0"
//                playerData.playerErrorCode = "456"
//                playerData.playerErrorMessage = "Time update has an error"
//                timeUpdateEvent.playerData = playerData
//
//                MUXSDKCore.dispatchEvent(
//                    timeUpdateEvent,
//                    forPlayer: self.playerName
//                )
//            }
//        )

//        DispatchQueue.main.asyncAfter(
//            deadline: .now() + 35,
//            execute: {
//                MUXSDKStats.dispatchError(
//                    "123",
//                    withMessage: "This is a test error",
//                    forPlayer: self.playerName
//                )
//            }
//        )
//
//        DispatchQueue.main.asyncAfter(
//            deadline: .now() + 44,
//            execute: {
//                MUXSDKStats.dispatchError(
//                    "123",
//                    withMessage: "This is another test error",
//                    forPlayer: self.playerName
//                )
//            }
//        )
//
//        DispatchQueue.main.asyncAfter(
//            deadline: .now() + 64,
//            execute: {
//                MUXSDKStats.dispatchError(
//                    "1234",
//                    withMessage: "This is another test error",
//                    forPlayer: self.playerName
//                )
//            }
//        )
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        playerViewController.player?.play()

        guard let scene = UIApplication.shared.connectedScenes.first else {
            return
        }

        if let sceneDelegate = scene.delegate as? SceneDelegate {
            sceneDelegate.videoViewController = self
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if !playerViewController.allowsPictureInPicturePlayback {
            playerViewController.player?.pause()

            MUXSDKStats.destroyPlayer(
                playerName
            )
        }

        super.viewWillDisappear(animated)
    }
}

extension BasicPlaybackExampleViewController: AVPlayerViewControllerDelegate {
    func playerViewControllerWillStartPictureInPicture(
        _ playerViewController: AVPlayerViewController
    ) {
        guard let scene = UIApplication.shared.connectedScenes.first else {
            return
        }

        if let sceneDelegate = scene.delegate as? SceneDelegate {
            sceneDelegate.enteringPictureInPicture = true
        }
    }
}
