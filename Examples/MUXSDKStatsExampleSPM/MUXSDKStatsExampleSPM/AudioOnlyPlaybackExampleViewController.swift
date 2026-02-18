//
//  AudioOnlyPlaybackExampleViewController.swift
//  MUXSDKStatsExampleSPM
//

import UIKit
import MUXSDKStats

class AudioOnlyPlaybackExampleViewController: UIViewController {
    var playbackURL: URL {
        let playbackID = ProcessInfo.processInfo.playbackID ?? "00ezSo01tK00mfbBKDLUtKnwVsUKF2y5cjBMvJwBh5Z0202g"

        return URL(
            string: "https://stream.mux.com/\(playbackID).m3u8"
        )!
    }
    let playerName = "AudioOnlyPlaybackExample"
    lazy var player = AVPlayer(url: playbackURL)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Step 1: Build Mux customer metadata.
        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoTitle = "Field Recording: A Rainy Summer Night"
        videoData.videoId = "AVPlayerAudioOnlyPlaybackExample"

        let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData,
            videoData: videoData,
            viewData: nil
        )!

        // Step 2: Start monitoring this AVPlayer with a stable player name.
        MUXSDKStats.monitorAVPlayer(
            player,
            withPlayerName: playerName,
            fixedPlayerSize: .zero,
            customerData: customerData
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }

    deinit {
        // Step 3: When done with this AVPlayer instance, call destroyPlayer to remove observers.
        player.pause()
        MUXSDKStats.destroyPlayer(playerName)
    }
}
