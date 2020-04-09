import UIKit
import AVKit
import AVFoundation
import MuxCore
import MUXSDKStats
import GoogleInteractiveMediaAds
import Mux_Stats_Google_IMA

class VideoPlayerController: AVPlayerViewController, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    var video: Dictionary<String, String>! = nil
    var timeObserverToken: Any! = nil
    var playComplete: Any! = nil
    var controller: AVPlayerViewController! = nil
    var url: URL! = nil
    var contentPlayhead: IMAContentPlayhead! = nil
    var adsLoader: IMAAdsLoader! = nil
    var adsManager: IMAAdsManager! = nil
    var imaListener: MuxImaListener! = nil

    let playName = "iOS AVPlayer"
    let adUrl = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpostpod&cmsid=496&vid=short_onecue&correlator="

    override func viewDidLoad() {
        super.viewDidLoad()
        let videoUrl = video["url"]!
        url = URL(string: videoUrl)
//        player = self.testAvPlayer()
//        player = self.testVideoChange()
//        player = self.testAvQueuePlayer()
        player = self.testImaSDK()

        let playerData = MUXSDKCustomerPlayerData(environmentKey: "ENV_KEY");
        playerData?.playerName = "AVPlayer"
        let videoData = MUXSDKCustomerVideoData();
        videoData.videoIsLive = false;
        videoData.videoTitle = "Title1"
        let playerBinding = MUXSDKStats.monitorAVPlayerViewController(self, withPlayerName: playName, playerData: playerData!, videoData: videoData);
        imaListener = MuxImaListener.init(playerBinding: playerBinding!)
        player!.play()
    }

    func testAvPlayer () -> AVPlayer {
        let item = AVPlayerItem(url: url!)
        player = AVPlayer(playerItem: item)
        return player!
    }

    func testVideoChange () -> AVPlayer {
        let item1 = AVPlayerItem(url: url!)
        let item2 = AVPlayerItem(url: URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!)
        player = AVPlayer(playerItem: item1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { // Change `2.0` to the desired number of seconds.
           // Code you want to be delayed
            let videoData = MUXSDKCustomerVideoData();
            videoData.videoTitle = "Title2"
            videoData.videoId = "applekeynote2010-2"
            MUXSDKStats.videoChange(forPlayer: self.playName, with: videoData)
            self.player!.replaceCurrentItem(with: item2)
            self.player!.play()
        }
        return player!
    }

    func testAvQueuePlayer () -> AVPlayer {
        let item1 = AVPlayerItem(url: url!)
        let item2 = AVPlayerItem(url: URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.playerItemDidReachEnd),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: item1
        )
        player = AVQueuePlayer(items: [item1, item2])
        return player!
    }

    func testImaSDK () -> AVPlayer {
        let item = AVPlayerItem(url: URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!)
        player = AVPlayer(playerItem: item)
        contentPlayhead = IMAAVPlayerContentPlayhead.init(avPlayer: player!)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.contentDidFinishPlaying),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: item
        )
        adsLoader = IMAAdsLoader.init()
        adsLoader.delegate = self;
        let adDisplayContainer = IMAAdDisplayContainer.init(adContainer: self.view)
        let request = IMAAdsRequest.init(
            adTagUrl: adUrl,
            adDisplayContainer: adDisplayContainer,
            contentPlayhead: (contentPlayhead as! IMAContentPlayhead & NSObjectProtocol),
            userContext: nil)
        adsLoader.requestAds(with: request)
        return player!
    }

    @objc func playerItemDidReachEnd (notification: NSNotification) {
        let videoData = MUXSDKCustomerVideoData();
        videoData.videoTitle = "Title2"
        videoData.videoId = "applekeynote2010-2"
        MUXSDKStats.videoChange(forPlayer: self.playName, with: videoData)
    }

    @objc func contentDidFinishPlaying (notification: NSNotification) {
        if ((notification.object as! AVPlayerItem) == player!.currentItem) {
            adsLoader.contentComplete()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
        cleanUp()
        super.viewWillDisappear(animated)
    }

    func cleanUp() {
        player!.removeTimeObserver(timeObserverToken)
        NotificationCenter.default.removeObserver(playComplete)
        MUXSDKStats.destroyPlayer(playName);
        player = nil
    }

    // pragma mark - IMAAdsLoaderDelegate
    func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        adsManager = adsLoadedData.adsManager;
        adsManager.delegate = self;
        let adsRenderingSettings = IMAAdsRenderingSettings.init()
        adsRenderingSettings.webOpenerPresentingController = self;
        adsManager.initialize(with: adsRenderingSettings)
    }

    func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        print("Error loading ads: \(String(describing: adErrorData.adError.message))")
        player!.play()
    }

    func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        if (event.type == IMAAdEventType.LOADED) {
            adsManager.start()
        }
        if (imaListener != nil) {
            imaListener.dispatchEvent(event)
        }
    }

    func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
      // Something went wrong with the ads manager after ads were loaded. Log the
      // error and play the content.
        NSLog("AdsManager error: \(String(describing: error.message))")
        player!.play()
        if (imaListener != nil) {
            imaListener.dispatchError(error.message)
        }
    }

    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
      // The SDK is going to play ads, so pause the content.
        player!.pause()
        if (imaListener != nil) {
            imaListener.onContentPauseOrResume(true)
        }
    }

    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
      // The SDK is done playing ads (at least for now), so resume the content.
        player!.play()
        if (imaListener != nil) {
            imaListener.onContentPauseOrResume(false)
        }
    }
}
