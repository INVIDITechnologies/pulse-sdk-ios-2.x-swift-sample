//
//  VideoPlayerView.swift
//  sampleplayer
//
//  Created by Selvamani S on 04/06/25.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @State private var player: AVPlayer?
    @State var videoItem: VideoItem?
    
    var body: some View {
           VStack {
               if let player = player {
                   PlayerViewController(player: player)
                       .frame(height: 300)
                       .onAppear {
                           player.play()
                       }
               } else {
                   Text("Loading...")
               }
           }
           .onAppear {
               setupPlayer(urlString: videoItem?.contentUrl)
           }
       }
       
       private func setupPlayer(urlString: String?) {
           guard let manifestURL = URL(string: urlString ?? "") else {return}
           let asset = AVURLAsset(url: manifestURL)
           let playerItem = AVPlayerItem(asset: asset)
           self.player = AVPlayer(playerItem: playerItem)
       }
}

struct PlayerViewController: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

#Preview {
    VideoPlayerView()
}
