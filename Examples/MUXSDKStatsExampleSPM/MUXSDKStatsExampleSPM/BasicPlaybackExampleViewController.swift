//
//  BasicPlaybackExampleViewController.swift
//  MUXSDKStatsExampleSPM
//

import UIKit
import MUXSDKStats

class BasicPlaybackExampleViewController: UIViewController {
    
    let adURL = URL(string: "https://stream.mux.com/00ezSo01tK00mfbBKDLUtKnwVsUKF2y5cjBMvJwBh5Z0202g.m3u8")!
    let contentURL = URL(string: "https://stream.mux.com/Cnb5DBaeQ1oprAd0100VJ02iT16EDU02bMg8jYtKFhHLuqQ.m3u8")!
    var notificationToken: Any?
    var playerBinding: MUXSDKPlayerBinding?
    
//    var playbackURL: URL {
//        let playbackID = ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
//
//        return URL(
//            string: "https://stream.mux.com/\(playbackID).m3u8"
//        )!
//    }
    let playerName = "AVPlayerViewControllerExample"
    lazy var playerViewController = AVPlayerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Step 1: Create your AVPlayer and assign it to AVPlayerViewController.
//        let player = AVPlayer(url: adURL)
        let player = AVPlayer(url: adURL)
        playerViewController.player = player
        
        let item = player.currentItem!
        notificationToken = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main) { [weak self] notif in
            guard let self, let playerBinding = self.playerBinding else { return }
            
            playerBinding.dispatchAdEvent(MUXSDKAdEndedEvent())
            playerBinding.dispatchAdEvent(MUXSDKAdBreakEndEvent())
            
            let newItem = AVPlayerItem(url: contentURL)
            let player = self.playerViewController.player!
            player.replaceCurrentItem(with: newItem)
            player.play()
            
            if let notificationToken = self.notificationToken {
                NotificationCenter.default.removeObserver(notificationToken)
            }
        }

        // Step 2: Build Mux customer metadata.
        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = "rhhn9fph0nog346n4tqb6bqda"//ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoId = "BasicPlaybackAVPlayerViewControllerExample"
        videoData.videoTitle = "automaticVideoChange disabled after calling monitor()"

        guard let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData,
            videoData: videoData,
            viewData: nil
        ) else {
            return
        }

        // Step 3: Start monitoring this player view controller with a stable player name.
        let playerBinding = MUXSDKStats.monitorAVPlayerViewController(
            playerViewController,
            withPlayerName: playerName,
            customerData: customerData
        )!
        self.playerBinding = playerBinding
        playerBinding.dispatchAdEvent(MUXSDKAdBreakStartEvent())
        playerBinding.dispatchAdEvent(MUXSDKAdPlayingEvent())
        
        // TODO - when does this need to be called? I think after monitorAVPlayerViewController
        MUXSDKStats.setAutomaticVideoChange(playerName, enabled: false)

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
