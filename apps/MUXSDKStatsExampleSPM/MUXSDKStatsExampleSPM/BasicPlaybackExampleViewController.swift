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
//            string: "https://test-streams.mux.dev/x36xhzz/url_6/193039199_mp4_h264_aac_hq_7.m3u8"
                        string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
            //            string: "https://stream.mux.com/\(playbackID).m3u8"
        )!
    }
    let playerName = "AVPlayerViewControllerExample"
    lazy var playerViewController = AVPlayerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoId = "BasicPlaybackAVPlayerViewControllerExample"
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

        // TODO: Should be an automated test case
        print("viewDidLoad: (not) About to delay monitoring")
//        Task {
//            try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
//            let _ = await MainActor.run {
                MUXSDKStats.monitorAVPlayerViewController(
                    playerViewController,
                    withPlayerName: playerName,
                    customerData: customerData!
                )
//            }
//        }
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
