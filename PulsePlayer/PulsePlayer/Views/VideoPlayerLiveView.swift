//
//  VideoPlayerLiveView.swift
//
//

import SwiftUI
import AVKit

struct VideoPlayerLiveView: View {
    let video: VideoItem
    
    private var player: AVPlayer? {
        guard let url = video.contentUrl else { return nil }
        return AVPlayer(url: url)
    }
    var body: some View {
        ZStack {
            if let player = player {
                ZStack {
                    VideoPlayer(player: player)
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            
                            Button(action: handleAdBreakClick) {
                                Text("Prepare Ads for next break")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.8))
                                    .foregroundColor(Color.black)
                                    .cornerRadius(4)
                            }
                            
                            Button(action: handlePlayClick) {
                                Text("Play Ads")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.8))
                                    .foregroundColor(Color.black)
                                    .cornerRadius(4)
                            }
                            
                            Button(action: handleExtendSessionClick) {
                                Text("Extend Session")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.8))
                                    .foregroundColor(Color.black)
                                    .cornerRadius(4)
                            }
                            
                            HStack {
                                
                                Spacer()
                                
                                Button(action: handleSkipAdClick) {
                                    Text("Skip Ad")
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.8))
                                        .foregroundColor(Color.black)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 40)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Text("Unable to load video")
                        .font(.headline)
                }
                .padding()
            }
        }
    }
    
    private func handleAdBreakClick() {
        print("request ads clicked")
        // Add logic here
    }
    
    private func handlePlayClick() {
        print("play ads clicked")
        // Add logic here
    }
    
    private func handleExtendSessionClick() {
        print("extend session clicked")
        // Add logic here
    }
    
    private func handleSkipAdClick() {
        print("Skip ad clicked")
        // Add logic here
    }
}


