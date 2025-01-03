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

//        var playerItems: [AVPlayerItem] = [
//            AVPlayerItem(
//                url: URL(
//                    string: "https://stream.mux.com/00ezSo01tK00mfbBKDLUtKnwVsUKF2y5cjBMvJwBh5Z0202g.m3u8"
//                )!
//            ),
//            AVPlayerItem(
//                url: URL(
//                    string: "https://stream.mux.com/u02xH9SB1ZZNNjPiQp4l6mhzBKJ101uExYx4LU02J5Xm88.m3u8"
//                )!
//            ),
//            AVPlayerItem(
//                url: URL(
//                    string: "https://stream.mux.com/O02XWwicmDZIo02hlioontZ00pkcPzHoUmXJ4W8f8lSY0000.m3u8"
//                )!
//            ),
//            AVPlayerItem(
//                url: URL(
//                    string: "https://stream.mux.com/KyU4B3aJB01jjk00EmZBkp9nRkeaZyTblN3EwmjhIqkcw.m3u8"
//                )!
//            ),
//            AVPlayerItem(
//                url: URL(
//                    string: "https://stream.mux.com/MNYGboUWoKTFMhq9Ado1ZJ1Gs7q02UMQsp4ZCa02YxhmQ.m3u8"
//                )!
//            ),
//        ]

//        let player = AVQueuePlayer(
//            items: playerItems
//        )

//        self.playerViewController.player = player
    }
    
    override func makeAVPlayer() -> AVPlayer {
        return AVQueuePlayer(items: playerItems)
    }
}

class VideoChangeExampleViewController: MultiplePlayerItemPlaybackExampleViewController {

    override var playerName: String {
        return "VideoChangeExample"
    }

    override func handlePlayerItemDidPlayToEnd(_ notification: Notification) {
        print("VideoChangeExampleViewController: handlePlayerItemDidPlayToEnd: called")
        // TODO: Example should have a flag for automaticVideoChange
//        let videoData = MUXSDKCustomerVideoData()
//        videoData.videoTitle = "Second Test Video in Queue"
//        videoData.videoId = "AVQueuePlayerExample-SecondTestVideo"
//
//        let customData = MUXSDKCustomData()
//        customData.customData1 = "VideoChangeExample"
//        customData.customData2 = "VideoChange-SecondTestVideo"
//
//        let customerData = MUXSDKCustomerData()
//        customerData.customerVideoData = videoData
//        customerData.customData = customData
//
//        MUXSDKStats.videoChange(
//            forPlayer: playerName,
//            with: customerData
//        )
    }
}

class MultiplePlayerItemPlaybackExampleViewController: UIViewController {
    var playerItems: [AVPlayerItem] = [
        AVPlayerItem(
            url: URL(
                string: "https://stream.mux.com/00ezSo01tK00mfbBKDLUtKnwVsUKF2y5cjBMvJwBh5Z0202g.m3u8"
            )!
        ),
        AVPlayerItem(
            url: URL(
                string: "https://stream.mux.com/u02xH9SB1ZZNNjPiQp4l6mhzBKJ101uExYx4LU02J5Xm88.m3u8"
            )!
        ),
        AVPlayerItem(
            url: URL(
                string: "https://stream.mux.com/O02XWwicmDZIo02hlioontZ00pkcPzHoUmXJ4W8f8lSY0000.m3u8"
            )!
        ),
        AVPlayerItem(
            url: URL(
                string: "https://stream.mux.com/KyU4B3aJB01jjk00EmZBkp9nRkeaZyTblN3EwmjhIqkcw.m3u8"
            )!
        ),
        AVPlayerItem(
            url: URL(
                string: "https://stream.mux.com/MNYGboUWoKTFMhq9Ado1ZJ1Gs7q02UMQsp4ZCa02YxhmQ.m3u8"
            )!
        ),
    ]

    var playerName: String {
        return "AVQueuePlayerExample"
    }
    lazy var playerViewController = AVPlayerViewController()
    var playerItemObservation: NSKeyValueObservation? = nil

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

//        let player = AVQueuePlayer(
//            items: playerItems
//        )
        let player = makeAVPlayer()
        playerViewController.player = player
    }
    
    open func makeAVPlayer() -> AVPlayer {
        return AVPlayer(
            playerItem: playerItems[0]
        )

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        displayPlayerViewController()

        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = ProcessInfo.processInfo.environmentKey

        let videoData = MUXSDKCustomerVideoData()
//        videoData.videoTitle = "First Test Video in Queue"
//        videoData.videoId = "AVQueuePlayerExample-FirstTestVideo"
        let currentItem = playerViewController.player?.currentItem
        videoData.videoTitle = "AVQueuePlayer as doc'd - item \(String(describing: findIndexOfAVPlayerItem(currentItem)))"
        
        let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData,
            videoData: videoData,
            viewData: nil
        )

        MUXSDKStats.monitorAVPlayerViewController(
            playerViewController,
            withPlayerName: playerName,
            customerData: customerData!
        )
        
        // here's one way, though it's not the doc'd way
        /*
        self.playerItemObservation = playerViewController.player?.observe(\.currentItem, options: [.new]) {[weak self] player, change in
            guard let self else {
                return
            }
            let item = change.newValue ?? nil
            let index = findIndexOfAVPlayerItem(item)
            print(">>> changing player item index: \(String(describing: index))")
            guard index >= 0 else {
                print(">>> not a reportable index")
                return
            }
            
            let videoData = MUXSDKCustomerVideoData()
            videoData.videoTitle = "AVQueuePlayer test - item \(String(describing: index))"
            let customerData = MUXSDKCustomerData(customerPlayerData: nil, videoData: videoData, viewData: nil)
            
            // TODO: this all has to go into the avqueueplayer example, with a switch for doing it or not
            MUXSDKStats.setCustomerData(customerData!, forPlayer: playerName)
        }
        */
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handlePlayerItemEnded(notif:)),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: playerItems[0]
        )
    }
    
    @objc func handlePlayerItemEnded(notif: NSNotification) {
        // as doc'd but for a list of player items
        
        let item = notif.object as! AVPlayerItem
        let itemEndedIndex = findIndexOfAVPlayerItem(item)
        let nextIndex = itemEndedIndex + 1
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)

        // if there's a next item, change video
        if nextIndex < playerItems.count {
            let videoData = MUXSDKCustomerVideoData()
            videoData.videoTitle = "AVQueuePlayer as-doc'd - item \(String(describing: nextIndex))"
            let customerData = MUXSDKCustomerData(customerPlayerData: nil, videoData: videoData, viewData: nil)
            
            MUXSDKStats.videoChange(forPlayer: playerName, with: customerData!)
            let nextItem = playerItems[nextIndex]
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.handlePlayerItemEnded(notif:)),
                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: nextItem
            )
        }
    }
    
    func findIndexOfAVPlayerItem(_ item: AVPlayerItem?) -> Int {
        if let item {
            return playerItems.lastIndex(where: {it in it.asset.isEqual(item.asset)}) ?? -1
        } else {
            return -1
        }
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
//        let videoData = MUXSDKCustomerVideoData()
//        videoData.videoTitle = "Second Test Video in Queue"
//        videoData.videoTitle = "SecondTestVideo"
//
//        let customerData = MUXSDKCustomerData()
//        customerData.customerVideoData = videoData
//
//        MUXSDKStats.videoChange(
//            forPlayer: playerName,
//            with: customerData
//        )
    }
}
