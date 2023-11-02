//
//  AudioOnlyPlaybackExampleViewController.swift
//  MUXSDKStatsExampleSPM
//

import AVFoundation
import UIKit

import MuxCore
import MUXSDKStats

class AudioOnlyPlaybackExampleViewController: UIViewController {
    var playbackURL: URL {
        let playbackID = ProcessInfo.processInfo.playbackID ?? "27BKMLqT01tOznamh45ntvWXg00eZBRq3IFLTHX2T1rbY"

        return URL(
            string: "https://stream.mux.com/\(playbackID).m3u8"
        )!
    }
    let playerName = "AudioOnlyPlaybackExample"
    lazy var player = AVPlayer(url: playbackURL)

    override func viewDidLoad() {
        super.viewDidLoad()

        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoId = "FieldRecordingARainySummerNight"
        videoData.videoTitle = "Field Recording: A Rainy Summer Night"

        let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData,
            videoData: videoData,
            viewData: nil
        )!

        MUXSDKMonitor.shared().startMonitoring(
            player: player,
            playerName: playerName,
            fixedPlayerSize: CGSize.zero,
            customerData: customerData
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        MUXSDKMonitor.shared().stopMonitoring(
            playerName: playerName
        )
        player.pause()
        super.viewWillDisappear(animated)
    }
}
