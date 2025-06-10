//
//  AudioPlayerService.swift
//  Headway Test App
//
//  Created by Sashko on 03/06/2025.
//

import Foundation
import AVFoundation
import ComposableArchitecture
import SwiftUI

@MainActor
protocol AudioPlayerServiceProtocol {
    var track: AudioTrack? { get }
    var currentTime: TimeInterval { get set }
    var speed: PlaybackSpeed { get set }
    var duration: TimeInterval { get }
    var state: PlaybackState { get }
    func play() throws
    func pause() throws
    func setTrack(_ track: AudioTrack) async throws
}

struct AudioPlayerClient: Sendable {
    var setTrack: @Sendable (AudioTrack, Bool) async throws -> Void
    var play: @Sendable () async throws -> Void
    var pause: @Sendable () async throws -> Void
    var stop: @Sendable () async -> Void
    var seek: @Sendable (TimeInterval) async -> Void
    var setPlaybackSpeed: @Sendable (PlaybackSpeed) async -> Void
    var cleanup: @Sendable () async -> Void
    var timeUpdates: @Sendable () async -> AsyncStream<TimeInterval>
    var playbackStateChanges: @Sendable () async -> AsyncStream<PlaybackState>
}

extension AudioPlayerClient: DependencyKey {
    static var liveValue: AudioPlayerClient {
        let manager = AudioPlayer()
        return AudioPlayerClient(
            setTrack: { (track, shouldPlay) in
                try await manager.setTrack(track, play: shouldPlay)
            },
            play: {
                try await manager.play()
            },
            pause: {
                try await manager.pause()
            },
            stop: {
                await manager.stop()
            },
            seek: { time in
                await manager.seek(to: time)
            },
            setPlaybackSpeed: { speed in
                await manager.setPlaybackSpeed(speed)
            },
            cleanup: {
                await manager.cleanup()
            },
            timeUpdates: {
                await manager.getTimeUpdates()
            },
            playbackStateChanges: {
                await manager.getPlaybackStateChanges()
            }
        )
    }
    
}

extension DependencyValues {
    var audioPlayerClient: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}
