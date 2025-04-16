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
    private static let MUX_DATA_ENV_KEY = "YOUR ENV KEY HERE"
    
    private let viewController = AVPlayerViewController()
    private let player = AVPlayer(url: URL(string: MEDIA_URL)!)
    
    @State private var playerBinding: MUXSDKPlayerBinding? = nil
    
    var body: some View {
        VStack {
            PlayerView(player: player, viewController: viewController)
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
        let viewerData = MUXSDKCustomerViewerData()
        viewerData.viewerDeviceCategory = "kiosk"
        viewerData.viewerDeviceModel = "ABC-12345"
        viewerData.viewerDeviceManufacturer = "Example Display Systems, Inc"
        
        return MUXSDKCustomerData(customerPlayerData: playerData, videoData: videoData, viewData: viewData, customData: MUXSDKCustomData(), viewerData: viewerData)!
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
