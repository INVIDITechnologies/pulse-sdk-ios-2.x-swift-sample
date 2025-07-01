//
//  VideoPlayerLiveView.swift
//
//

import SwiftUI
import AVKit
import Combine
#if os(iOS)
import Pulse
#elseif os(tvOS)
import Pulse_tvOS
#endif

struct VideoPlayerLiveView: View {
    let video: VideoItem
    @StateObject private var liveViewModel = LiveViewModel()
    
    var body: some View {
        ZStack {
            videoPlayerView
            controlsView
        }
        .onAppear {
            liveViewModel.loadPulseSession(video: video)
        }
    }
    
    private var videoPlayerView: some View {
        Group {
            if let player = liveViewModel.player {
                VideoPlayer(player: player)
                    .onAppear {
//                        liveViewModel.observePlayerReady()
                    }
                    .onDisappear {
                        liveViewModel.cleanup()
                    }
                    .edgesIgnoringSafeArea(.all)
            } else {
                ProgressView("Loading Video...")
            }
        }
    }
    
    private var controlsView: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                controlButton(title: "Prepare Ads for next break", action:  liveViewModel.handlePreapareAdsClick)
                controlButton(title: "Play Ads", action: liveViewModel.handlePlayAdClick)
                controlButton(title: "Extend Session", action: liveViewModel.handleExtendSessionClick)
                if liveViewModel.isShowingSkip {
                                    controlButton(title: liveViewModel.skipButtonTitle, action: liveViewModel.handleSkipAdClick)
                                                }
            }
        }
        .padding()
        .padding(.bottom, 40)
    }
 
    private func controlButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.8))
                .foregroundColor(Color.black)
                .cornerRadius(4)
        }
//        .disabled(!liveViewModel.skipEnabled)
    }
}

