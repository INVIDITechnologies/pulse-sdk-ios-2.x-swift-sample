//
//  VideoItem.swift
//  PulsePlayer
//
//  Created by Selvamani S on 04/06/25.
//

import Foundation

struct VideoItem :  Codable, Identifiable {
    var id = UUID()
    
    let tags: [String]?
    let contentTitle: String
    let contentId: String
    let midrollPositions: [Int]?
    let contentDuration: Int?
    let contentUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case tags
        case contentTitle = "content-title"
        case contentId = "content-id"
        case midrollPositions = "midroll-positions"
        case contentDuration = "content-duration"
        case contentUrl = "content-url"
    }
    
}
