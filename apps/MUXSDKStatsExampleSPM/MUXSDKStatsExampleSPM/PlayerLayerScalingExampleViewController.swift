//
//  PlayerLayerScalingExampleViewController.swift
//  MUXSDKStatsExampleSPM
//

import UIKit

import MUXSDKStats

class PlayerLayerScalingExampleViewController: UIViewController {
    var playbackURL: URL {
        let playbackID = ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"

        return URL(
            string: "https://stream.mux.com/\(playbackID).m3u8"
        )!
    }
    let playerName = "AVPlayerLayerScalingExample"

    lazy var playerView = PlayerView()

    override func viewDidLoad() {
        super.viewDidLoad()

        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
        videoData.videoTitle = "Video Behind the Scenes"
        videoData.videoId = "AVPlayerLayerPlaybackExampleScaling"

        let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData,
            videoData: videoData,
            viewData: nil
        )!

        playerView.backgroundColor = .black

        playerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerView)
        view.addConstraints([
            view.centerXAnchor.constraint(
                equalTo: playerView.centerXAnchor
            ),
            view.centerYAnchor.constraint(
                equalTo: playerView.centerYAnchor
            ),
            view.widthAnchor.constraint(
                equalTo: playerView.widthAnchor,
                multiplier: 1.0
            ),
            view.heightAnchor.constraint(
                equalTo: playerView.heightAnchor,
                multiplier: 0.5
            ),
        ])

        playerView.player = AVPlayer(
            url: playbackURL
        )

        guard let playerLayer = playerView.layer as? AVPlayerLayer else {
            return
        }

        MUXSDKStats.monitorAVPlayerLayer(
            playerLayer,
            withPlayerName: playerName,
            customerData: customerData
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNewAccessLogEntryNotification(_:)),
            name: AVPlayerItem.newAccessLogEntryNotification,
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView.player?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        MUXSDKStats.destroyPlayer(playerName)
        playerView.player?.pause()
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
    }

    @objc func handleNewAccessLogEntryNotification(
        _ notification: Notification
    ) {
        guard let accessLog = playerView.player?.currentItem?.accessLog() else {
            precondition(false)
            return
        }

        guard let playerExtendedLogDirectoryPath = ProcessInfo.processInfo.simulatorSharedResourcesDirectory else {
            precondition(false)
            return
        }

        let playerExtendedLogDirectoryURL = URL(
            fileURLWithPath: playerExtendedLogDirectoryPath
        )

        guard let playerExtendedLogFileName = ProcessInfo.processInfo.playerExtendedLogFileName else {
            precondition(false)
            return
        }

        let playerExtendedLogFilePath = playerExtendedLogDirectoryURL
        .appendingPathComponent(
            "\(playerExtendedLogFileName).txt",
            conformingTo: .text
        )

        guard let extendedLogData = accessLog.extendedLogData() else {
            precondition(false)
            return
        }

        do {
            try extendedLogData.write(
                to: playerExtendedLogFilePath
            )
        } catch {
            precondition(false)
        }
    }
}
