//
//  BookSummaryModels.swift
//  Headway Test App
//
//  Created by Sashko on 06/06/2025.
//

import Foundation

enum SummaryFormat: CaseIterable, Equatable, Sendable {
    case audio, text
    
    var iconName: String {
        switch self {
        case .audio: return "headphones"
        case .text: return "text.alignleft"
        }
    }
}

struct AudioTrack: Equatable, Sendable {
    let url: URL
    let duration: TimeInterval
}

struct BookSummary: Equatable, Sendable {
    let image: URL
    let keypoints: [BookSummaryKeyPoint]
}

struct BookSummaryKeyPoint: Equatable, Sendable {
    let audio: AudioTrack
    let title: String
    let textTranscription: String
    let index: UInt
    let id: UInt
}
