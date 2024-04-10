//
//  ContentView.swift
//  MUXSDKStatsExampleSPMVisionOS
//

import AVKit
import SwiftUI
import RealityKit
import RealityKitContent

import MUXSDKStats
import MuxCore

struct PlayerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AVPlayerViewController {

    }

    func updateUIViewController(
        _ controller: AVPlayerViewController,
        context: Context
    ) {
        
    }


}

func makeVideoPlayer() -> VideoPlayer<EmptyView> {
//    let playbackID = "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
//    let url = URL(
//        string: "https://stream.mux.com/\(playbackID).m3u8"
//    )!

    let url = URL(
        string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/historic_planet_content_2023-10-26-3d-video/main.m3u8"
    )!

    let player = AVPlayer(
        url: url
    )
    let videoPlayer = VideoPlayer(
        player: player
    )

    let customerPlayerData = MUXSDKCustomerPlayerData()
    customerPlayerData.environmentKey = "qr9665qr78dac0hqld9bjofps"

    let customerData = MUXSDKCustomerData()
    customerData.customerPlayerData = customerPlayerData

    MUXSDKStats.monitorAVPlayer(
        player,
        withPlayerName: "BasicPlayback",
        fixedPlayerSize: CGSize(width: 100.00, height: 100.0),
        customerData: MUXSDKCustomerData()
    )

    return videoPlayer
}

struct ContentView: View {
    var body: some View {
        VStack {
            Model3D(named: "Scene", bundle: realityKitContentBundle)
                .padding(.bottom, 50)
            makeVideoPlayer()
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
