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
//        player = self.testAvPlayer()
        player = self.testAvQueuePlayer()

        let playerData = MUXSDKCustomerPlayerData(environmentKey: "cqtqt2jfbq235huvso0djbn56");
        playerData?.playerName = "AVPlayer"
        let videoData = MUXSDKCustomerVideoData();
        videoData.videoIsLive = false;
        videoData.videoTitle = "Title.15.1"
        MUXSDKStats.monitorAVPlayerViewController(self, withPlayerName: playName, playerData: playerData!, videoData: videoData);
        player!.play()
    }
    
    func testAvPlayer () -> AVPlayer {
        let item1 = AVPlayerItem(url: URL(string: "https://stream.mux.com/jY02nK1sxQKmJiQ7ltXY01w9LZQWdtNetE.m3u8")!)
        let item2 = AVPlayerItem(url: URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!)
        player = AVPlayer(playerItem: item1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { // Change `2.0` to the desired number of seconds.
           // Code you want to be delayed
            let videoData = MUXSDKCustomerVideoData();
            videoData.videoTitle = "Title.15.2"
            videoData.videoId = "applekeynote2010-2"
            MUXSDKStats.videoChange(forPlayer: self.playName, with: videoData)
            self.player!.replaceCurrentItem(with: item2)
            self.player!.play()
        }
        return player!
    }
    
    func testAvQueuePlayer () -> AVPlayer {
        let item1 = AVPlayerItem(url: URL(string: "https://stream.mux.com/jY02nK1sxQKmJiQ7ltXY01w9LZQWdtNetE.m3u8")!)
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

    @objc func playerItemDidReachEnd (notification: NSNotification) {
        let videoData = MUXSDKCustomerVideoData();
        videoData.videoTitle = "Title.15.2"
        videoData.videoId = "applekeynote2010-2"
        MUXSDKStats.avQueuePlayerNextItem(forPlayer: self.playName, with: videoData)
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
