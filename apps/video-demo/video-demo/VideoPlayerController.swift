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

        let item1 = AVPlayerItem(url: URL(string: "https://stream.mux.com/jY02nK1sxQKmJiQ7ltXY01w9LZQWdtNetE.m3u8")!)
        let item2 = AVPlayerItem(url: URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.playerItemDidReachEnd),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: item1
        )
        player = AVQueuePlayer(items: [item1, item2])

        let playerData = MUXSDKCustomerPlayerData(environmentKey: "cqtqt2jfbq235huvso0djbn56");
        playerData?.playerName = "AVPlayer"
        let videoData = MUXSDKCustomerVideoData();
        videoData.videoIsLive = false;
        videoData.videoTitle = "Title.9.1"
        MUXSDKStats.monitorAVPlayerViewController(self, withPlayerName: playName, playerData: playerData!, videoData: videoData);
        player!.play()
    }

    @objc func playerItemDidReachEnd (notification: NSNotification) {
        let videoData = MUXSDKCustomerVideoData();
        videoData.videoTitle = "Title.9.2"
        videoData.videoId = "applekeynote2010-2"
        MUXSDKStats.videoChange(forPlayer: playName, with: videoData)
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
