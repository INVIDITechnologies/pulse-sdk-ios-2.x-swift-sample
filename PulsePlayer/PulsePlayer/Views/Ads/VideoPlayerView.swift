//
//  VideoPlayerView.swift
//  PulsePlayer
//
//  Created by Dino Sunny on 04/06/25.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let video: VideoItem
    
    private var player: AVPlayer? {
        guard let url = video.contentUrl else { return nil }
        return AVPlayer(url: url)
    }
    var body: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
                    .edgesIgnoringSafeArea(.all)
            } else {
                VStack(spacing: 12) {
                    Text("Unable to load video")
                        .font(.headline)
                }
                .padding()
            }
        }
    }
}
