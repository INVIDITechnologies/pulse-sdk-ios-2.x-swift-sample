//
//  ContentView.swift
//  PulsePlayer
//
//  Created by Dino Sunny on 03/06/25.
//

import SwiftUI


struct ContentView: View {
    @State private var videos = [VideoItem]()
    
    var body: some View {
        
        VStack {
            List(videos) { video in
                NavigationLink {
                    VideoPlayerView(videoItem: video)
                } label: {
                    Text(video.contentTitle)
                }
            }
        }
        .onAppear {
            videos = decode("library.json")
        }
    }
    
    func decode(_ file: String) -> [VideoItem] {
        guard let url = Bundle.main.url(forResource: file, withExtension: nil) else {
            print("Faliled to locate \(file) in bundle")
            fatalError("Faliled to locate \(file) in bundle")
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("Failed to load file from \(file) from bundle")
            fatalError("Failed to load file from \(file) from bundle")
        }
        
        let decoder = JSONDecoder()
        
        guard let loadedFile = try? decoder.decode([VideoItem].self, from: data) else {
            print("Failed to decode \(file) from bundle")
            fatalError("Failed to decode \(file) from bundle")
        }
        
        return loadedFile
    }
}


#Preview {
    ContentView()
}
