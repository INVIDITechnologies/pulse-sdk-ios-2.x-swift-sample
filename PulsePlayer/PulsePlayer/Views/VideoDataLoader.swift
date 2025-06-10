//
//  VideoDataLoader.swift
//
//

import Foundation

enum VideoType: String, CaseIterable, Identifiable {
    case live = "Live"
    case vod  = "VOD"

    var id: String { rawValue }
    var fileName: String {
        switch self {
        case .vod:  return "library.json"
        case .live: return "library_live.json"
        }
    }
}

struct VideoDataManager {
    static func loadVideos(for type: VideoType) -> [VideoItem] {
        decode(type.fileName)
    }

    private static func decode(_ fileName: String) -> [VideoItem] {
        // 1) Find the JSON file in the app bundle
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            fatalError("Failed to locate \(fileName) in bundle.")
        }

        // 2) Load its Data
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(fileName) from bundle.")
        }

        // 3) Decode into `[VideoItem]`
        let decoder = JSONDecoder()
        guard let items = try? decoder.decode([VideoItem].self, from: data) else {
            fatalError("Failed to decode \(fileName). Check that your JSON matches VideoItem.")
        }

        return items
    }
}
