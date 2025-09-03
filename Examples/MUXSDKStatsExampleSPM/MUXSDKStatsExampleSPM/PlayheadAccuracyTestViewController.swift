//
//  PlayheadAccuracyTestViewController.swift
//  MUXSDKStatsExampleSPM
//
//  Created to test the playhead accuracy issue where seeking followed by seek
//  sometimes records an inaccurate playhead value for the playing event.

import UIKit
import AVKit
import MUXSDKStats

class PlayheadAccuracyTestViewController: UIViewController {
    
    // MARK: - Properties
    
    var playbackURL: URL {
        let playbackID = ProcessInfo.processInfo.playbackID ?? "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
        return URL(string: "https://stream.mux.com/\(playbackID).m3u8")!
    }
    
    let playerName = "PlayheadAccuracyTestPlayer"
    lazy var playerViewController = AVPlayerViewController()
    
    // UI Elements
    var autoTestButton: UIButton!
    
    // Test state
    private var isAutoTestRunning = false
    private var autoTestTimer: Timer?
    private var testStep = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPlayer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerViewController.player?.play()
        print("🎬 Playback started")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoTest()
        playerViewController.player?.pause()
        MUXSDKStats.destroyPlayer(playerName)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Playhead Accuracy Test"
        
        // Always create UI elements programmatically
        setupUIProgrammatically()
    }
    
    private func setupUIProgrammatically() {
        view.backgroundColor = .systemBackground
        
        // Auto test button
        autoTestButton = UIButton(type: .system)
        autoTestButton.setTitle("Run Extensive Auto Test", for: .normal)
        autoTestButton.addTarget(self, action: #selector(toggleAutoTest), for: .touchUpInside)
        autoTestButton.backgroundColor = .systemBlue
        autoTestButton.setTitleColor(.white, for: .normal)
        autoTestButton.layer.cornerRadius = 8
        autoTestButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(autoTestButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Auto test button - centered on screen
            autoTestButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            autoTestButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            autoTestButton.widthAnchor.constraint(equalToConstant: 200),
            autoTestButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupPlayer() {
        let playerData = MUXSDKCustomerPlayerData()
        playerData.environmentKey = "vkuh75eimbhmqo7cgo0iaiuce"
        
        let videoData = MUXSDKCustomerVideoData()
        videoData.videoId = "PlayheadAccuracyTest"
        videoData.videoTitle = "Playhead Accuracy Test Video"
        
        let customerData = MUXSDKCustomerData(
            customerPlayerData: playerData,
            videoData: videoData,
            viewData: nil
        )
        
        let player = AVPlayer(url: playbackURL)
        playerViewController.player = player
        playerViewController.delegate = self
        playerViewController.allowsPictureInPicturePlayback = false
        
        displayPlayerViewController()
        
        MUXSDKStats.monitorAVPlayerViewController(
            playerViewController,
            withPlayerName: playerName,
            customerData: customerData!
        )
        
        print("📱 Player setup complete")
    }
    
    private func displayPlayerViewController() {
        addChild(playerViewController)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerViewController.view)
        
        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            playerViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerViewController.view.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        playerViewController.didMove(toParent: self)
    }
    
    // MARK: - Actions
    
    @objc private func toggleAutoTest() {
        if isAutoTestRunning {
            stopAutoTest()
        } else {
            startAutoTest()
        }
    }
    
    // MARK: - Seeking Logic
    
    private func performSeek(to time: Double, description: String) {
        guard let player = playerViewController.player else { return }
        
        let seekTime = CMTime(seconds: time, preferredTimescale: 1000)
        let currentTime = player.currentTime()
        let currentTimeSeconds = CMTimeGetSeconds(currentTime)
        
        print("🎯 \(description)")
        print("   Current time: \(String(format: "%.2f", currentTimeSeconds))s")
        print("   Seeking to: \(String(format: "%.2f", time))s")
        
        player.seek(to: seekTime) { [weak self] completed in
            DispatchQueue.main.async {
                if completed {
                    print("✅ Seek completed to \(String(format: "%.2f", time))s")
                } else {
                    print("❌ Seek failed to \(String(format: "%.2f", time))s")
                }
            }
        }
    }
    
    // MARK: - Auto Test
    
    private func startAutoTest() {
        isAutoTestRunning = true
        testStep = 0
        autoTestButton.setTitle("Stop Auto Test", for: .normal)
        autoTestButton.backgroundColor = .systemRed
        
        print("🤖 Starting EXTENSIVE automated playhead accuracy test...")
        print("   This will perform multiple rapid seeks to trigger the issue")
        
        // Wait 2 seconds, then start the test sequence
        autoTestTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.executeAutoTestStep()
        }
    }
    
    private func stopAutoTest() {
        isAutoTestRunning = false
        autoTestTimer?.invalidate()
        autoTestTimer = nil
        autoTestButton.setTitle("Run Extensive Auto Test", for: .normal)
        autoTestButton.backgroundColor = .systemBlue
        print("🛑 Auto test stopped")
    }
    
    private func executeAutoTestStep() {
        guard isAutoTestRunning else { return }
        
        switch testStep {
        case 0:
            print("📊 Step 1: Baseline - letting video play for 2 seconds")
            testStep += 1
            autoTestTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                self?.executeAutoTestStep()
            }
            
        case 1:
            print("📊 Step 2: First seek to 5 seconds")
            performSeek(to: 5.0, description: "Auto test - First seek")
            testStep += 1
            autoTestTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.executeAutoTestStep()
            }
            
        case 2:
            print("📊 Step 3: Second seek to 10 seconds (rapid)")
            performSeek(to: 10.0, description: "Auto test - Second seek")
            testStep += 1
            autoTestTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                self?.executeAutoTestStep()
            }
            
        case 3:
            print("📊 Step 4: Third seek to 15 seconds (very rapid)")
            performSeek(to: 15.0, description: "Auto test - Third seek")
            testStep += 1
            autoTestTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
                self?.executeAutoTestStep()
            }
            
        case 4:
            print("📊 Step 5: Fourth seek to 20 seconds (extremely rapid)")
            performSeek(to: 20.0, description: "Auto test - Fourth seek")
            testStep += 1
            autoTestTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.executeAutoTestStep()
            }
            
        case 5:
            print("📊 Step 6: Fifth seek to 25 seconds (back-to-back)")
            performSeek(to: 25.0, description: "Auto test - Fifth seek")
            testStep += 1
            autoTestTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.executeAutoTestStep()
            }
            
        case 6:
            print("📊 Step 7: Sixth seek to 30 seconds (back-to-back)")
            performSeek(to: 30.0, description: "Auto test - Sixth seek")
            testStep += 1
            autoTestTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                self?.executeAutoTestStep()
            }
            
        case 7:
            print("📊 Step 8: Final observation - letting video play for 2 seconds")
            testStep += 1
            autoTestTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                self?.executeAutoTestStep()
            }
            
        default:
            print("✅ EXTENSIVE Auto test completed!")
            print("   Check the dashboard for playhead accuracy issues")
            print("   Look for seeking/seeked events with inaccurate playhead values")
            print("   Multiple rapid seeks should have triggered the issue")
            stopAutoTest()
        }
    }
    

}

// MARK: - AVPlayerViewControllerDelegate

extension PlayheadAccuracyTestViewController: AVPlayerViewControllerDelegate {
    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        // Handle PiP if needed
    }
}
