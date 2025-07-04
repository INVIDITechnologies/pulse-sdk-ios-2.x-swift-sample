//
//  VideoPlayerVodView.swift
//  PulsePlayer
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

struct VideoPlayerVodView: View {
    let video: VideoItem
    @StateObject private var vodViewModel =  VODViewModel()
    
    var body: some View {
        ZStack {
            videoPlayerView
            controlsView
        }
        .onAppear {
            vodViewModel.loadPulseSession(video: video)
        }
    }
    
    private var videoPlayerView: some View {
        Group {
            if let player = vodViewModel.player {
                AVPlayerControllerVod(player: player, vodViewModel: vodViewModel)
                    .onAppear {
//                        vodViewModel.observePlayerReady()
                    }
                    .onDisappear {
                        vodViewModel.cleanup()
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
                if vodViewModel.isShowingSkip {
                                    controlButton(title: vodViewModel.skipButtonTitle, action: vodViewModel.handleSkipAdClick)
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
        .disabled(!vodViewModel.skipEnabled)
    }
}

struct AVPlayerControllerVod : UIViewControllerRepresentable {
    var player : AVPlayer
    var vodViewModel = VODViewModel()
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        vodViewModel.playerController(uiViewController)
    }
}
