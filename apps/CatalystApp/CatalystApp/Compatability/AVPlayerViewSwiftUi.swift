//
//  AVPlayerViewSwiftUi.swift
//  CatalystApp
//
//  Created by Emily Dixon on 10/28/22.
//

import Foundation
import SwiftUI
import AVKit

/**
 * Wraps an `AVPlayerViewController` with SwiftUI, providing accwss to its `AVPlayer`
 */
struct AVPlayerViewSwiftUi : UIViewControllerRepresentable {
    
    /**
     * The `AVPlayerViewController` wrapped by this object
     */
    let viewController: AVPlayerViewController
    private var player: AVPlayer?
    
    init(player: AVPlayer, viewController: AVPlayerViewController) {
        self.player = player
        self.viewController = viewController
    }
    
    mutating func changePlayer(player: AVPlayer) {
        viewController.player = player
        self.player = player
    }
    
    mutating func removePlayer() {
        viewController.player = nil
        player = nil
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        viewController.player = player
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Nothing to do
    }
    
    typealias UIViewControllerType = AVPlayerViewController
}
