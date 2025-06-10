//
//  AudioPlayerFeature.swift
//  Headway Test App
//
//  Created by Sashko on 07/06/2025.
//

import Foundation
import ComposableArchitecture

@Reducer
struct AudioPlayerFeature: Sendable {
    
    @ObservableState
    struct State: Equatable, Sendable {
        var track: AudioTrack?
        var currentTime: TimeInterval = 0
        var duration: TimeInterval = 0
        var playbackState: PlaybackState = .idle
        var playbackSpeed: PlaybackSpeed = .normal
        var isPlaying: Bool {
            playbackState == .playing
        }
        var isLoading: Bool {
            playbackState == .loading
        }
        var progress: Double {
            guard duration > 0 else { return 0 }
            return currentTime / duration
        }
    }
    
    enum Action: Equatable, Sendable {
        // User Actions
        case setTrack(AudioTrack, immidiatePlay: Bool)
        case play
        case pause
        case stop
        case seek(TimeInterval)
        case setPlaybackSpeed(PlaybackSpeed)
        case cleanup
        case cleanUpFinished
        
        // Internal Actions
        case _trackLoaded(AudioTrack)
        case _trackLoadFailed(AudioPlayerError)
        case _playbackStateChanged(PlaybackState)
        case _timeUpdate(TimeInterval)
        case _startStreamListeners
    }
    
    @Dependency(\.audioPlayerClient) var audioPlayerClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setTrack(track, play):
                state.track = track
                state.currentTime = 0
                state.duration = track.duration
                state.playbackState = .loading
                
                return .run { send in
                    do {
                        await send(._startStreamListeners)
                        try await audioPlayerClient.setTrack(track, play)
                        await send(._trackLoaded(track))
                    } catch {
                        let audioError = error as? AudioPlayerError ?? .playbackFailed
                        await send(._trackLoadFailed(audioError))
                    }
                }
                
            case .play:
                guard state.track != nil else {
                    state.playbackState = .error(.playerIsNotConfigured)
                    return .none
                }
                
                return .run { _ in
                    try await audioPlayerClient.play()
                }
                
            case .pause:
                return .run { _ in
                    try await audioPlayerClient.pause()
                }
                
            case .stop:
                return .run { _ in
                    await audioPlayerClient.stop()
                }
                
            case let .seek(time):
                state.currentTime = max(0, min(time, state.duration))
                return .run { _ in
                    await audioPlayerClient.seek(time)
                }
                
            case let .setPlaybackSpeed(speed):
                state.playbackSpeed = speed
                return .run { _ in
                    await audioPlayerClient.setPlaybackSpeed(speed)
                }
                
            case ._startStreamListeners:
                return .merge(
                    .run { send in
                        for await time in await audioPlayerClient.timeUpdates() {
                            await send(._timeUpdate(time))
                        }
                    },
                    .run { send in
                        for await state in await audioPlayerClient.playbackStateChanges() {
                            await send(._playbackStateChanged(state))
                        }
                    }
                )
            case ._trackLoaded(let track):
                state.duration = track.duration
                return .none
                
            case let ._trackLoadFailed(error):
                state.playbackState = .error(error)
                return .none
                
            case let ._playbackStateChanged(newState):
                state.playbackState = newState
                return .none
                
            case let ._timeUpdate(time):
                state.currentTime = time
                return .none
            case .cleanup:
                return .run { send in
                    await audioPlayerClient.cleanup()
                    await send(.cleanUpFinished)
                }
            case .cleanUpFinished:
                return .none
            }
        }
        ._printChanges()
    }
}
