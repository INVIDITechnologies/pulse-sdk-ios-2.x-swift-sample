//
//  PlayerViewModel.swift
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

class LiveViewModel: NSObject, ObservableObject, OOPulseSessionDelegate {
    @Published var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var timeControlStatusObserver: NSKeyValueObservation?
    var playbackCompletionObserver: AnyCancellable?
    var cancellables = Set<AnyCancellable>()
    var skipAdTimer: AnyCancellable?
    var avPLayerItem: AVPlayerItem?
    var contentAsset: AVAsset?
    var adAsset: AVAsset?
    var currentPulseVideoAd: OOPulseVideoAd?
    var isSessionExtensionRequested: Bool = false
    var playAd: Bool = false
    var adStarted: Bool = false
    var contentStarted: Bool = false
    var adPaused: Bool = false
    var duringContent: Bool = false
    var duringAd: Bool = false
    var playVideo: Bool = false
    var currentAdProgress: Double = 0
    var currentContentProgress: Double = 0
    var session: OOPulseSession?
    var ooContentMetadata: OOContentMetadata?
    var ooRequestSettings: OORequestSettings?
    var video: VideoItem?
    @Published var skipButtonTitle = ""
    @Published var isShowingSkip = false
    @Published var skipEnabled = false
    
    var timeObserverToken: Any?
       @Published var currentTime: CMTime = .zero
       var currentTimeString: String {
           let seconds = Int(CMTimeGetSeconds(currentTime))
           return "\(seconds) seconds"
       }
    
    func startPositinChangeListener() {
        let interval = CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC)) // Fires every 0.2 playback seconds
           timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
               self?.currentTime = time
               print("Current playback time: \(CMTimeGetSeconds(time)) seconds")
               self?.observePlayerReady()
               if(self?.duringContent == true) {
                   if(self?.player != nil && self?.self .player!.currentTime().seconds != nil) {
                       self?.currentContentProgress = self?.player!.currentTime().seconds ?? 0
                       if(self?.session != nil) {
                           self?.session?.contentPositionChanged(self!.currentContentProgress)
                           print("Current Content playback time from player: \(String(describing: self?.currentContentProgress)) seconds")
                       }
                   }
                   // Check for session extension scenario.
                   if(self?.video?.contentTitle != nil && self?.video?.contentTitle == "Session extension" && self?.isSessionExtensionRequested == false) {
                       // Session extension logic
                   }
               } else if(self?.duringAd == true) {
                   if(self?.player != nil && self?.self .player!.currentTime().seconds != nil) {
                       self?.currentAdProgress = self?.player!.currentTime().seconds ?? 0
                       if(self?.currentPulseVideoAd != nil) {
                           self?.currentPulseVideoAd!.adPositionChanged(self!.currentAdProgress)
                           print("Current Ad playback time from player: \( String(describing: self?.currentAdProgress)) seconds")
                       }
                   }
               }
           }
       }
       func stopObserving() {
           if let token = timeObserverToken {
               player?.removeTimeObserver(token)
               timeObserverToken = nil
           }
       }

    
    // Player initialized
    func initializePlayer() {
        player!.play()
        if(playVideo) {
            seek(to: CMTime(seconds: currentContentProgress, preferredTimescale: 60000))
        }
    }
    
    // Player Observer
    func observePlayerReady() {
        guard let item = playerItem else { return }
        item.publisher(for: \.status)
            .sink { [weak self] status in
                if status == .readyToPlay {
//                    self?.player?.play()
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
                    self?.playbackCompletionObserver = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
                        .sink { _ in
                          // Playback completion listener
                            self?.handPlaybackCompleted()
                        }
//                  self?.startObserving()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadPulseSession(video: VideoItem) {
        print("Session Config...")
        self.video = video
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
        guard skipEnabled, let ad = currentPulseVideoAd else { return }
                     ad.adSkipped()
                     cleanupSkipState()
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
    
    func handPlaybackCompleted() {
        print("Playback completed")
    }
    
    func seek(to time: CMTime) {
        player?.seek(to: time)
    }
    
    // Pulse Session Callbacks
    func startContentPlayback() {
        print("startContentPlayback from delegate",video?.contentUrl as Any)
        contentStarted = true
        if(contentStarted) {
            session?.contentStarted()
        }
        
        cleanupSkipState()
        playVideoContent()
    }
    
    func start(_ adBreak: (any OOPulseAdBreak)!) {
        print("startAdBreak from delegate")
    }
    
    func startAdPlayback(with ad: (any OOPulseVideoAd)!, timeout: TimeInterval) {
        print("startAdPlayback from delegate")
        currentPulseVideoAd = ad
        playAdContent(videoAd: ad, timeout: Double())
    }
    
    func sessionEnded() {
        print("sessionEnded from delegate")
    }
    
    func illegalOperationOccurredWithError(_ error: (any Error)!) {
        print("illegalOperationOccurredWithError from delegate")
    }
    
    func playVideoContent() {
        print("Playing video content")
        guard let url = video?.contentUrl else { return }
        duringContent = true
        playVideo = true
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
//        player?.play()
        initializePlayer()
        startPositinChangeListener()
    }
    
    func playAdContent(videoAd: OOPulseVideoAd, timeout: TimeInterval) {
        print("Playing ad content for ad: \(videoAd)")
        guard let mediaFile = selectAppropriateMediaFile(for: videoAd) else {
            duringAd = false
            adStarted = false
            currentPulseVideoAd!.adFailedWithError(OOPulseAdError.requestFailed)
            adPaused = false
            return
        }
        duringContent = false
        playAd = true
        print("Ad URL to play: \(String(describing: mediaFile.url()))")
        playerItem = AVPlayerItem(url: mediaFile.url())
        player = AVPlayer(playerItem: playerItem)
        initializePlayer()
        if !adStarted {
            currentPulseVideoAd?.adStarted()
        }
        
        // Skip Ad trigger logic
        let offset = currentPulseVideoAd!.skipOffset
        isShowingSkip = true
        skipEnabled = false
        updateSkipTitle(remaining: Int(offset()))

        // check any existing timer
        skipAdTimer?.cancel()

        // Start countdown timer
        skipAdTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.skipAdCountdown()
            }
    }
    
    func selectAppropriateMediaFile(for videoAd: OOPulseVideoAd) -> OOMediaFile? {
        print("Selecting appropriate media file for ad: \(videoAd)")
        
        guard let mediaFiles = videoAd.mediaFiles(), !mediaFiles.isEmpty else {
            return OOMediaFile()
        }
        
        let highestBitrateMediaFile = mediaFiles.max(by: { $0.bitRate() < $1.bitRate() })
        
        print("Selecting highest bitrate media file: \(String(describing: highestBitrateMediaFile))")
        
        return highestBitrateMediaFile
    }
    
    func skipAdCountdown() {
        let remainingTime = Int(currentPulseVideoAd!.skipOffset() - (player?.currentTime().seconds ?? 0))
            if remainingTime > 0 {
                updateSkipTitle(remaining: remainingTime)
            } else {
                enableSkip()
            }
   }
    
    func updateSkipTitle(remaining: Int) {
           skipButtonTitle = "Skip ad in \(remaining)s"
    }

    func enableSkip() {
           skipEnabled = true
           skipButtonTitle = "Skip ad"
           skipAdTimer?.cancel()
    }
       
   func cleanupSkipState() {
           isShowingSkip = false
           skipEnabled = false
           skipButtonTitle = ""
           skipAdTimer?.cancel()
   }
    
    // Called on onDisappear
    func cleanup() {
        cancellables.removeAll()
        stopObserving()
        player?.pause()
        player = nil
        playerItem = nil
    }
}
