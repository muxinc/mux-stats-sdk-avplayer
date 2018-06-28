import UIKit
import AVKit
import AVFoundation
import MuxCore
import MUXSDKStats

class VideoPlayerController: AVPlayerViewController {
    var video: Dictionary<String, String>! = nil
    var timeObserverToken: Any! = nil
    var playComplete: Any! = nil
    var controller: AVPlayerViewController! = nil

    let playName = "iOS AVPlayer"

    override func viewDidLoad() {
        super.viewDidLoad()

        let videoUrl = video["url"]!
        let url = URL(string: videoUrl)
        player = AVPlayer(url: url!)

        let cpd = MUXSDKCustomerPlayerData(environmentKey: "img");
        cpd?.playerName = "AVPlayer"
        cpd?.environmentKey = "YOUR_ENVIRONMENT_KEY"
        let cvd = MUXSDKCustomerVideoData();
        cvd.videoIsLive = false;
        cvd.videoTitle = video["title"]!
        cvd.videoStreamType = "mp4"
        MUXSDKStats.monitorAVPlayerViewController(self, withPlayerName: playName, playerData: cpd!, videoData: cvd);

        timeObserverToken = player!.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5,
                                                                               preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                                                           queue: DispatchQueue.main) { time in
                                                            let timeElapsed = Float(CMTimeGetSeconds(time))
                                                            print ("current time " + timeElapsed.description)
        }
        playComplete = NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(note:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
        player!.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func playerDidFinishPlaying(note: NSNotification) {
        self.navigationController?.popViewController(animated: true)
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
}
