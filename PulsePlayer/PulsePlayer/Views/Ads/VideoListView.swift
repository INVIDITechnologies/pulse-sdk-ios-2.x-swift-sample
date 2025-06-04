//
//  VideoListView.swift
//  PulsePlayer
//
//  Created by Dino Sunny on 04/06/25.
//

import SwiftUI

struct VideoListView: View {
    @State private var videos = [VideoItem]()
    @State private var selectedType: VideoType = .vod
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Select Type", selection: $selectedType) {
                    ForEach(VideoType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                List(videos) { video in
                    NavigationLink(destination: VideoPlayerView(video: video)) {
                        Text(video.contentTitle)
                    }
                }
            }
            .navigationTitle("Pulse Sample App")
        }
        .onAppear {
            videos = VideoDataManager.loadVideos(for: selectedType)
        }
        .onChange(of: selectedType) {
            videos = VideoDataManager.loadVideos(for: selectedType)
        }
    }
}

#Preview {
    VideoListView()
}
