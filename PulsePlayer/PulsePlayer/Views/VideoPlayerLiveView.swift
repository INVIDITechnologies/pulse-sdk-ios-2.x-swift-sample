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
                AVPlayerControllerLive(player: player, liveViewModel: liveViewModel)
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
                if liveViewModel.isShowingPrepareAd {
                    controlButton(title: "Prepare Ads for next break", action:  liveViewModel.handlePreapareAdsClick)
                }
                if liveViewModel.isShowingPlayingAd {
                    controlButton(title: "Play Ads", action: liveViewModel.handlePlayAdClick)
                }
                if liveViewModel.isShowingExtendSession {
                    controlButton(title: "Extend Session", action: liveViewModel.handleExtendSessionClick)
                }
                if liveViewModel.isShowingSkip {
                     controlButton(title: liveViewModel.skipButtonTitle, action: liveViewModel.handleSkipAdClick)
                }
            }
        }
        .padding()
        .padding(.bottom, 40)
        #if os(tvOS)
        .focusSection()
        #endif
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
        .disabled(!liveViewModel.skipEnabled)
    }
}

struct AVPlayerControllerLive : UIViewControllerRepresentable {
    var player : AVPlayer
    var liveViewModel = LiveViewModel()
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        liveViewModel.playerController(uiViewController)
    }
}
