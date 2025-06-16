//
//  VideoPlayerLiveView.swift
//
//

import SwiftUI
import AVKit
import Combine
import Pulse

struct VideoPlayerLiveView: View {
    let video: VideoItem
    @StateObject private var viewModel = PlayerViewModel()
    
    var body: some View {
        ZStack {
            videoPlayerView
            controlsView
        }
        .onAppear {
            viewModel.initializePlayer(from: video)
        }
    }
    
    private var videoPlayerView: some View {
        Group {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .onAppear {
                        viewModel.observePlayerReady()
                    }
                    .onDisappear {
                        viewModel.cleanup()
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
                controlButton(title: "Prepare Ads for next break", action:  viewModel.handleAdBreakClick)
                controlButton(title: "Play Ads", action: viewModel.handlePlayAdClick)
                controlButton(title: "Extend Session", action: viewModel.handleExtendSessionClick)
                controlButton(title: "Skip Ad", action: viewModel.handleSkipAdClick)
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
    }
}

class PlayerViewModel: NSObject, ObservableObject, OOPulseSessionDelegate {
    @Published var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var timeControlStatusObserver: NSKeyValueObservation?
    var cancellables = Set<AnyCancellable>()
    var avPLayerItem: AVPlayerItem?
    var contentAsset: AVAsset?
    var adAsset: AVAsset?
    var videoAd: OOPulseVideoAd?
    var isSessionExtensionRequested: Bool = false
    var session: OOPulseSession?
    var ooContentMetadata: OOContentMetadata?
    var ooRequestSettings: OORequestSettings?
    
    // Player initialized
    func initializePlayer(from video: VideoItem) {
        guard let url = video.contentUrl else { return }
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        loadPulseSession(video: video)
    }
    
    // Player Observer
    func observePlayerReady() {
        guard let item = playerItem else { return }
        item.publisher(for: \.status)
            .sink { [weak self] status in
                if status == .readyToPlay {
                    self?.player?.play()
                    self?.timeControlStatusObserver = self?.player?.observe(\.timeControlStatus, options: [.initial, .new]) { [self] player, change in
                            switch player.timeControlStatus {
                            case .playing:
                                self?.handlePlaybackStarted()
                            case .paused:
                                self?.handlePlaybackPaused()
                            case .waitingToPlayAtSpecifiedRate:
                                self?.handleBufferingOrWaiting()
                            @unknown default:
                                break
                            }
                        }
                }
            }
            .store(in: &cancellables)
    }
    
    func loadPulseSession(video: VideoItem) {
        print("Session Config...")
        // ContentMetaData configuration
        ooContentMetadata = OOContentMetadata()
        ooContentMetadata!.category = video.category
        ooContentMetadata!.tags = video.tags
        ooContentMetadata!.contentForm = .long
        ooContentMetadata!.duration = Double(video.contentDuration ?? 0)
        ooContentMetadata!.identifier = video.contentId
        // RequestSettings configuration
        ooRequestSettings = OORequestSettings()
        ooRequestSettings!.userAgentForThirdPartyRequests = OOUserAgentFormat.IAB
        ooRequestSettings!.linearPlaybackPositions = video.midrollPositions
        //Pulse Host setup and Session trigger.
        OOPulse.setPulseHost("https://pulse-demo.videoplaza.tv",deviceContainer: nil, persistentId: nil)
            OOPulse.logDebugMessages(true)
            session = OOPulse.session(with: ooContentMetadata, requestSettings: ooRequestSettings)
            session?.start(with: self)
    }
    
    // Custom Button Events
    func handleAdBreakClick() {
        print("Request ads clicked")
    }
    
    func handlePlayAdClick() {
        print("Play ads clicked")
    }
    
    func handleExtendSessionClick() {
        print("Extend session clicked")
        guard session != nil else { return }
        isSessionExtensionRequested = true
    }
    
    func handleSkipAdClick() {
        print("Skip ad clicked")
    }
    
    // Player Events
    func handlePlaybackStarted() {
          print("Playback started")
    }

    func handlePlaybackPaused() {
          print("Playback paused")
    }

    func handleBufferingOrWaiting() {
          print("Buffering or waiting")
    }
    
    func seek(to time: CMTime) {
        player?.seek(to: time)
    }
    
    // Pulse Session Callbacks
    func startContentPlayback() {
        print("startContentPlayback from delegate")
//        player?.play()
    }
    
    func start(_ adBreak: (any OOPulseAdBreak)!) {
        print("startAdBreak from delegate")
    }
    
    func startAdPlayback(with ad: (any OOPulseVideoAd)!, timeout: TimeInterval) {
        print("startAdPlayback from delegate")
    }
    
    func sessionEnded() {
        print("sessionEnded from delegate")
    }
    
    func illegalOperationOccurredWithError(_ error: (any Error)!) {
        print("illegalOperationOccurredWithError from delegate")
    }
    
    // Called on onDisappear
    func cleanup() {
        cancellables.removeAll()
        player?.pause()
        player = nil
        playerItem = nil
    }
}
