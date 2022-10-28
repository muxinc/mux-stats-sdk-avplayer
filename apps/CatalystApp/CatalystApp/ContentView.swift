//
//  ContentView.swift
//  CatalystApp
//
//  Created by Emily Dixon on 10/21/22.
//

import SwiftUI
import AVKit
import AVFoundation
import MUXSDKStats

struct ContentView: View {
    
    private static let MEDIA_URL = "https://stream.mux.com/v69RSHhFelSm4701snP22dYz2jICy4E4FUyk02rW4gxRM.m3u8"
    private static let MUX_DATA_ENV_KEY = "jp06n8nvbl6u8g3u40cpvi9u2" // TODO: Your Key Here
    
    private let viewController = AVPlayerViewController()
    private let player = AVPlayer(url: URL(string: MEDIA_URL)!)
    
    @State private var playerBinding: MUXSDKPlayerBinding? = nil
    
    var body: some View {
        VStack {
            AVPlayerViewSwiftUi(player: player, viewController: viewController)
                .onAppear() {
                    playerBinding = MUXSDKStats.monitorAVPlayerViewController(viewController, withPlayerName: "player", customerData: customerData())
                    player.play()
                }
                .onDisappear() {
                    player.pause()
                    playerBinding?.detachAVPlayer()
                }
        }
        .edgesIgnoringSafeArea(.all) // fullscreen
    }
    
    private func customerData() -> MUXSDKCustomerData {
        let videoData = MUXSDKCustomerVideoData()
        videoData.videoTitle = "Big Buck Bunny"
        videoData.videoSourceUrl = ContentView.MEDIA_URL
        let playerData = MUXSDKCustomerPlayerData()
        playerData.propertyKey = ContentView.MUX_DATA_ENV_KEY
        let viewData = MUXSDKCustomerViewData()
        viewData.viewSessionId = "1"
        
        return MUXSDKCustomerData(customerPlayerData: playerData, videoData: videoData, viewData: viewData)!
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
