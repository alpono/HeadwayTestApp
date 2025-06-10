//
//  AudioPlayerModels.swift
//  Headway Test App
//
//  Created by Sashko on 10/06/2025.
//

import Foundation

enum AudioPlayerError: Error, Equatable, Sendable {
    case fileNotFound
    case playbackFailed
    case playerIsNotConfigured
    case invalidURL
}

enum PlaybackState: Equatable, Sendable {
    case idle
    case loading
    case playing
    case paused
    case stopped
    case error(AudioPlayerError)
}

enum PlaybackSpeed: CaseIterable, Sendable {
    case normal, bitFaster, fast, veryFast
    
    var value: Float {
        switch self {
        case .normal: return 1.0
        case .bitFaster: return 1.25
        case .fast: return 1.5
        case .veryFast: return 2.0
        }
    }
    
    var next: PlaybackSpeed {
        switch self {
        case .normal: return .bitFaster
        case .bitFaster: return .fast
        case .fast: return .veryFast
        case .veryFast: return .normal
        }
    }
}
