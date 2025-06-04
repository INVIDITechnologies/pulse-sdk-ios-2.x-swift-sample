//
//  VideoItemVod.swift
//  PulsePlayer
//
//  Created by Dino Sunny on 04/06/25.
//

import Foundation

struct VideoItem: Identifiable, Codable {
    // Give each video a unique UUID so SwiftUI List never collapses duplicates
    let id = UUID()

    let tags: [String]?
    let contentTitle: String
    let contentId: String?
    let contentDuration: Int?
    let contentUrl: URL?
    let midrollPositions: [Int]?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case tags
        case contentTitle     = "content-title"
        case contentId        = "content-id"
        case contentDuration  = "content-duration"
        case contentUrl       = "content-url"
        case midrollPositions = "midroll-positions"
        case category
    }
}
