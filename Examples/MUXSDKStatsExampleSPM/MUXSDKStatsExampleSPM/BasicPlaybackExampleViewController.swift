//
//  ViewController.swift
//  MUXSDKStatsExampleSPM
//

import UIKit
import AVKit
import MUXSDKStats

class BasicPlaybackExampleViewController: UIViewController {

    var playbackURL: URL {
        // normal(muxed) HLS asset
        //        let playbackID = ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
//        return URL(
//            string: "https://stream.mux.com/\(playbackID).m3u8"
//        )!
        
        // CMAF asset
        URL("https://cdn.bitmovin.com/content/assets/art-of-motion-dash-hls-progressive/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!
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
        
        if #available(iOS 18, *) {
            Task {
                try! await keepLoggingAVMetricsEvents(player.currentItem!)
            }
        }
        
        displayPlayerViewController()

        MUXSDKStats.monitorAVPlayerViewController(
            playerViewController,
            withPlayerName: playerName,
            customerData: customerData!
        )
    }
    
    @available(iOS 18, *)
    func keepLoggingAVMetricsEvents(_ item: AVPlayerItem) async throws {
        //var it = item.allMetrics().makeAsyncIterator()
        var it = item.allMetrics().makeAsyncIterator()
//        var resourceRequests = item.metrics(forType: AVMetricHLSMediaSegmentRequestEvent.self).makeAsyncIterator()
//        var playlistRequests = item.metrics(forType: AVMetricHLSPlaylistRequestEvent.self).makeAsyncIterator()
        
        var segmentRequests = item.metrics(forType: AVMetricHLSMediaSegmentRequestEvent.self).makeAsyncIterator()
        var playlistRequests = item.metrics(forType: AVMetricHLSPlaylistRequestEvent.self).makeAsyncIterator()
        
        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                while true {
                    let segmentEvent = try! await segmentRequests.next()
                    guard let segmentEvent else { return }
//                    print("segment request url: \(segmentEvent.url?.absoluteString ?? "nil")")
                    let urlFromPlaylistEvent =  segmentEvent.url
                    let urlFromNetworkTransactionMetrics = segmentEvent.mediaResourceRequestEvent?.networkTransactionMetrics?.transactionMetrics.last?.request.url
                    let urlFromResourceRequest = segmentEvent.mediaResourceRequestEvent!.url
                    print("segment request url from event: \(urlFromPlaylistEvent?.absoluteString ?? "nil")")
                    print("segment request url from Transaction metrics: \(urlFromNetworkTransactionMetrics?.absoluteString ?? "nil")")
                    print("segment request url resourceRequestEvent: \(urlFromResourceRequest?.absoluteString ?? "nil")")
                    print("segment request media type: \(segmentEvent.mediaType.rawValue)")
                    let mediaTypeFromSwitch: String
                    switch segmentEvent.mediaType {
                        case .audio:
                        mediaTypeFromSwitch = "audio"
                    case .video:
                        mediaTypeFromSwitch = "video"
                    default:
                        mediaTypeFromSwitch = "not audio or video"
                    }
                    print("segment request media type (selected by switch statement): \(mediaTypeFromSwitch)")
                    print("")
                }
            }
            group.addTask {
                while true {
                    let playlistEvent = try! await playlistRequests.next()
                    guard let playlistEvent else { return }
//                    print("playlist request url: \(playlistEvent.url?.absoluteString ?? "nil")")
                    let urlFromPlaylistEvent =  playlistEvent.url
                    let urlFromNetworkTransactionMetrics = playlistEvent.mediaResourceRequestEvent?.networkTransactionMetrics?.transactionMetrics.last?.request.url
                    let urlFromResourceRequest = playlistEvent.mediaResourceRequestEvent!.url
                    print("playlist is MVP::\(playlistEvent.isMultivariantPlaylist)")
                    print("playlist request url from event: \(urlFromPlaylistEvent?.absoluteString ?? "nil")")
                    print("playlist request url from Transaction metrics: \(urlFromNetworkTransactionMetrics?.absoluteString ?? "nil")")
                    print("playlist request url resourceRequestEvent: \(urlFromResourceRequest?.absoluteString ?? "nil")")
                    print("playlist request media type: \(playlistEvent.mediaType.rawValue)")
                    print("")
                }
            }
        }
        
//        while true {
//            let event = try await it.next()
//            print("got one: \(String(describing: event))")
            
//            let resourceEvent = try await resourceRequests.next()
//            guard let resourceEvent else { return }
//            print("segment request media type: \(resourceEvent.mediaType.rawValue)")
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
