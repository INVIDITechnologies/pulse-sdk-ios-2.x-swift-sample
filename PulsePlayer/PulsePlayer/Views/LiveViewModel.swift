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

class LiveViewModel: NSObject, ObservableObject, INPulseLiveSessionDelegate {
    @Published var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var playerItemPlaylist: [AVPlayerItem] = []
    var timeControlStatusObserver: NSKeyValueObservation?
    var playerItemObserver: NSKeyValueObservation?
    var playbackCompletionObserver: AnyCancellable?
    var cancellables = Set<AnyCancellable>()
    var skipAdTimer: AnyCancellable?
    var contentAsset: AVAsset?
    var adAsset: AVAsset?
    var adPlaylist: [OOPulseVideoAd] = []
    var currentPulseVideoAd: OOPulseVideoAd?
    var isSessionExtensionRequested: Bool = false
    var playAd: Bool = false
    var prepareAdClicked: Bool = false
    var adStarted: Bool = false
    var contentStarted: Bool = false
    var duringContent: Bool = false
    var duringAd: Bool = false
    var currentAdProgress: Double = 0
    var currentContentProgress: Double = 0
    var session: OOPulseSession?
    var liveSession: INPulseLiveSession?
    var ooContentMetadata: OOContentMetadata?
    var ooRequestSettings: OORequestSettings?
    var videoItem: VideoItem?
    @Published var skipButtonTitle = ""
    @Published var isShowingSkip = false
    @Published var skipEnabled = false
    var playbackPosition : Array = [Float()]
    var extendedPlaybackPositions : Array = [Float()]
    var mAdBreaks : Array = [INPulseLiveAdBreak]()
    var midRollBreakIndex: Int = 0
    var currentIndex : Int = 0
    
    var timeObserverToken: Any?
       @Published var currentTime: CMTime = .zero
       var currentTimeString: String {
           let seconds = Int(CMTimeGetSeconds(currentTime))
           return "\(seconds) seconds"
       }

    
    // Player initialized
    func initializePlayer() {
        guard let url = videoItem?.contentUrl else { return }
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player!.play()
    }
    
    func loadPulseSession(video: VideoItem) {
        print("Session Config...")
        self.videoItem = video
        // ContentMetaData configuration
        ooContentMetadata = OOContentMetadata()
        ooContentMetadata!.tags = video.tags
        
        // RequestSettings configuration
        ooRequestSettings = OORequestSettings()
        if(video.midrollPositions != nil && video.midrollPositions?.count != 0) {
            for i in 0..<video.midrollPositions!.count {
                playbackPosition.append(Float(video.midrollPositions![i]))
            }
        }
        ooRequestSettings!.linearPlaybackPositions = video.midrollPositions
        //Pulse Host setup and Session trigger.
        OOPulse.setPulseHost("https://pulse-demo.videoplaza.tv",deviceContainer: nil, persistentId: nil)
            OOPulse.logDebugMessages(true)
        liveSession = OOPulse.liveSession(with: ooContentMetadata, requestSettings: ooRequestSettings, liveSessionListener: self)
        playVideoContent()
//        observePlayerReady()
    }
 
    // Custom Button Events
    func handlePreapareAdsClick() {
        print("Request ads from AdBreak clicked")
        if(midRollBreakIndex < playbackPosition.count-1) {
            midRollBreakIndex += 1
            let position: Float = playbackPosition[midRollBreakIndex]
            var adBreak: INPulseLiveAdBreak?
            adBreak = liveSession?.getAdBreak(OOAdBreakType.MIDROLL,atIndex: position)
            print("Triggered getAdBreak for playback position - \(position) ")
            if(adBreak != nil) {
                prepareAdClicked = true
                adBreak?.getAllLinearAds { [weak self] ads in
                self?.prepareAdsForPlay(ads)
                self?.mAdBreaks.append(adBreak!)
                print("Ads fetched for playback position - \(position)")
            }
            }
            
        } else {
            print("No more playback position available for current session. Extend session to request for more breaks.")
        }
    }
    
    func handlePlayAdClick() {
        print("Play ads clicked")
        if(!mAdBreaks.isEmpty) {
            if(mAdBreaks[0].playableAdsTotal() > 0) {
                // Play Fetched Ad fro AdBreak.
                playAdContent()
                mAdBreaks.remove(at: 0)
            } else {
                print("No ads to show.")
            }
        } else {
            print("No AdBreak available")
        }
    }
    
    func handleExtendSessionClick() {
        print("Request a session extension for two midRolls at 30s after previous midRoll break.")
        // ContentMetaData configuration
        var ooContentMetadata: OOContentMetadata?
        ooContentMetadata = OOContentMetadata()
        ooContentMetadata!.tags = videoItem?.tags
        // RequestSettings configuration
        var updatedRequestSettings: OORequestSettings?
        var newPlaybackPositions : Array = [Float()]
        updatedRequestSettings?.linearPlaybackPositions = videoItem?.midrollPositions
        newPlaybackPositions.append(!playbackPosition.isEmpty ? (playbackPosition.last! + 30) : 30)
        newPlaybackPositions.append(!playbackPosition.isEmpty ? (playbackPosition.last! + 60) : 60)
        updatedRequestSettings?.linearPlaybackPositions = newPlaybackPositions
        extendedPlaybackPositions = newPlaybackPositions
        updatedRequestSettings?.insertionPointFilter = OOInsertionPointType.playbackPosition
        liveSession?.extend(with: ooContentMetadata, requestSettings: updatedRequestSettings, success: { /*[weak self] in*/
            print("Extension request successful")
        })
        print("Session Extended for playback positions - ",newPlaybackPositions)
        
        if(!extendedPlaybackPositions.isEmpty) {
            playbackPosition = extendedPlaybackPositions
            midRollBreakIndex = 0
        }
    }
    
    func handleSkipAdClick() {
        print("Skip ad clicked")
        guard skipEnabled, let ad = currentPulseVideoAd else { return }
        ad.adSkipped()
        currentPulseVideoAd = nil
        cleanupSkipState()
        stopAdProgressTracking()
        if(playAd){
            playNextItem()
        }
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
        if(playAd){
            if(currentPulseVideoAd != nil) {
                currentPulseVideoAd?.adFinished()
                stopAdProgressTracking()
            }
            playNextItem()
        }
    }
    
    func seek(to time: CMTime) {
        player?.seek(to: time)
    }
    
    // Pulse Session Callbacks
    func sessionRequestSuccessful() {
        print("SessionRequest Successful")
        var liveAdBreak: INPulseLiveAdBreak?
        liveAdBreak = liveSession?.getAdBreak(OOAdBreakType.PREROLL)
        if(liveAdBreak != nil) {
            liveAdBreak?.getAllLinearAds { [weak self] ads in
                if(ads!.count > 0) {
                    self?.prepareAdsForPlay(ads)
                }
            }
        }
    }
    
    func sessionRequestFailedWithError (_ error: (any Error)!) {
        print("illegalOperationOccurredWithError from delegate")
    }
    
    // In class functions
    func prepareAdsForPlay(_ ads: [(any OOPulseVideoAd)]?) {
        print("prepareAdsForPlay from delegate")
        if(ads == nil || ads!.isEmpty) {
            print( "PulseManagerLive - ", "No ads available.")
            var text: String = "Inventory ad returned from Pulse for PreRoll position."
            if(midRollBreakIndex > 0) {
                text = "Inventory ad returned from Pulse for playback position -  \(playbackPosition[midRollBreakIndex-1])."
            }
            print(text)
            return
        }
        adPlaylist = ads!
        var adIndex: Int = 0
        playerItemPlaylist = []
        ads?.forEach { ad in
            if let videoAd = ad as? OOPulseVideoAd {
                print("Preparing video ad: \(String(describing: videoAd.mediaFiles().first))")
                guard let mediaFile = selectAppropriateMediaFile(for: videoAd) else {
                    duringAd = false
                    adStarted = false
                    currentPulseVideoAd!.adFailedWithError(OOPulseAdError.requestFailed)
                    return
                }
                
                print("Ad URL to play: \(String(describing: mediaFile.url()))")
                playerItemPlaylist.append(AVPlayerItem(url: mediaFile.url()))
//                playAdContent(videoAd: ad as! OOPulseVideoAd)
            }
        }
        if(!prepareAdClicked) {
            playAdContent()
        }
//        observePlayerReady()
        if(adIndex > 0){
            if(midRollBreakIndex > 0) {
                print("%d ads are added for adBreak %d at playback position %f", adIndex, midRollBreakIndex, playbackPosition[midRollBreakIndex - 1])
            } else {
                print("%d ads are added for preRoll or postRoll adBreak.", adIndex)
//                if(!playAdClicked) {
                    playAdContent()
//                }
            }
        }
    }
    
    func playVideoContent() {
        print("Playing video content")
        playAd = false
        duringAd = false
        duringContent = true
        stopAdProgressTracking()
        cleanupSkipState()
        initializePlayer()
    }
    
    func playAdContent() {
        print("Playing ad content:")
        duringContent = false
        playAd = true
        prepareAdClicked = false
        playItem(at: currentIndex)
        currentPulseVideoAd?.adStarted()
    }
    
    func startAdProgressTracking() {
        let interval = CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC)) // Fires every 0.2 playback seconds
           timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
               self?.currentTime = time
               print("Current playback time: \(CMTimeGetSeconds(time)) seconds")
//               self?.observePlayerReady()
            
                       self?.currentAdProgress = self?.player!.currentTime().seconds ?? 0
                       if(self?.currentPulseVideoAd != nil) {
                           self?.currentPulseVideoAd!.adPositionChanged(self!.currentAdProgress)
                           self?.updateSkipButton(currentAdPlayHead: Int( self!.currentAdProgress))
                           print("Current Ad Progress: \( String(describing: self?.currentAdProgress)) seconds")
                       }
           }
       }
    
    // Player Observer
    func observePlayerReady() {
        guard var item = playerItem else { return }
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
                    
                    // Observe current media Item changes
                    self?.playerItemObserver = self?.player?.observe(\.currentItem, options: [.new, .old]) {player, change in
                                DispatchQueue.main.async {
                                    item = (change.newValue ?? nil)!
                                    if let newItem = change.newValue as? AVPlayerItem {
                                        print("AVPlayerItem changed to: \(newItem.duration)")
                                    }
                                }
                            }
                }
            }
            .store(in: &cancellables)
    }
    
    func stopAdProgressTracking() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        playerItemObserver?.invalidate()
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
    
    func playItem(at index: Int) {
            currentPulseVideoAd = adPlaylist[index]
            currentPulseVideoAd?.adStarted()
            guard playerItemPlaylist.indices.contains(index) else { return }
            playerItem = playerItemPlaylist[index]
            player?.replaceCurrentItem(with: playerItem)
            player?.play()
            startAdProgressTracking()
            observePlayerReady()
            // Skip Ad trigger logic
            let offset = currentPulseVideoAd!.skipOffset
            isShowingSkip = true
            skipEnabled = false
            updateSkipTitle(remaining: Int(offset()))
    }
    
    func playNextItem() {
            currentIndex += 1
            if currentIndex < playerItemPlaylist.count {
                playItem(at: currentIndex)
            } else {
                print("Finished all Media items")
                currentIndex = 0
                playVideoContent()
            }
    }
    
    func updateSkipButton(currentAdPlayHead: Int) {
        if(currentPulseVideoAd?.isSkippable() ?? false && !skipEnabled) {
            var remainingTime: Int = 0
            remainingTime = Int(currentPulseVideoAd?.skipOffset() ?? 0) - currentAdPlayHead
            skipButtonTitle = "Skip ad in \(remainingTime)s"
        }
        if (Int(currentPulseVideoAd!.skipOffset())) <= currentAdPlayHead {
            skipButtonTitle = "Skip Ad"
            skipEnabled = true
        }
        // Move to next media
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
//           skipAdTimer?.cancel()
    }
       
   func cleanupSkipState() {
           isShowingSkip = false
           skipEnabled = false
           skipButtonTitle = ""
//           skipAdTimer?.cancel()
   }
    
    // Called on onDisappear
    func cleanup() {
        cancellables.removeAll()
        stopAdProgressTracking()
        player?.pause()
        player = nil
        playerItem = nil
    }
}
