//
//  VideoListView.swift
//
//

import SwiftUI

struct VideoListView: View {
    @State private var videos = [VideoItem]()
    @State private var selectedType: VideoType = .live
    
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
                    NavigationLink(
                        destination: destinationView(for: video)
                    ) {
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
    
    @ViewBuilder
    private func destinationView(for video: VideoItem) -> some View {
        if selectedType == .vod {
            VideoPlayerVodView(video: video)
        } else {
            VideoPlayerLiveView(video: video)
        }
    }
}


#Preview {
    VideoListView()
}
