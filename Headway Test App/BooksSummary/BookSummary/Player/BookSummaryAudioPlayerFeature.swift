//
//  BookSummaryPlayer.swift
//  Headway Test App
//
//  Created by Sashko on 03/06/2025.
//

import Foundation
import ComposableArchitecture
import Combine

@Reducer
struct BookSummaryPlayerFeature: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var audioPlayerState = AudioPlayerFeature.State()
        var currentKeyPointIndex = 0
        var bookSummary: BookSummary?
        var currentKeyPoint: BookSummaryKeyPoint? {
            guard let keypoints = bookSummary?.keypoints,
                  keypoints.indices.contains(currentKeyPointIndex) else {
                return nil
            }
            return keypoints[currentKeyPointIndex]
        }
        var totalKeyPoints: Int {
            bookSummary?.keypoints.count ?? 0
        }
        var hasNextKeyPoint: Bool {
            currentKeyPointIndex + 1 < totalKeyPoints
        }
        var hasPreviousKeyPoint: Bool {
            currentKeyPointIndex > 0
        }
        var isPlaying: Bool {
            audioPlayerState.isPlaying
        }
        var isLoading: Bool {
            audioPlayerState.isLoading
        }
        var currentTime: TimeInterval {
            audioPlayerState.currentTime
        }
        var totalDuration: TimeInterval {
            audioPlayerState.duration
        }
        var playbackSpeed: PlaybackSpeed {
            audioPlayerState.playbackSpeed
        }
        var progress: Double {
            audioPlayerState.progress
        }
        var playbackState: PlaybackState {
            audioPlayerState.playbackState
        }
        var keyPointProgress: String {
            guard totalKeyPoints > 0 else { return "" }
            return "KEY POINT \(currentKeyPointIndex + 1) OF \(totalKeyPoints)"
        }
    }
    
    enum Action: Equatable, Sendable {
        // User Actions
        case setSummary(BookSummary)
        case playPauseButtonTapped
        case previousKeyPointTapped
        case nextKeyPointTapped
        case skipBackward5SecondsTapped
        case skipForward10SecondsTapped
        case seekToTime(TimeInterval)
        case speedButtonTapped
        case cleanup
        case cleanupFinished
        case keyPointChanged(shouldPlay: Bool)
        case handlePlaybackFinished
        case audioPlayer(AudioPlayerFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.audioPlayerState, action: \.audioPlayer) {
            AudioPlayerFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .setSummary(summary):
                state.bookSummary = summary
                state.currentKeyPointIndex = 0
                guard let firstKeyPoint = summary.keypoints.first else {
                    return .none
                }
                return .send(.audioPlayer(.setTrack(firstKeyPoint.audio, immidiatePlay: false)))
                
            case .playPauseButtonTapped:
                return .send(.audioPlayer(state.isPlaying ? .pause : .play))
                
            case .previousKeyPointTapped:
                guard state.hasPreviousKeyPoint else { return .none }
                let newIndex = state.currentKeyPointIndex - 1
                state.currentKeyPointIndex = newIndex
                return .send(.keyPointChanged(shouldPlay: state.isPlaying))
                
            case .nextKeyPointTapped:
                guard state.hasNextKeyPoint else { return .none }
                let newIndex = state.currentKeyPointIndex + 1
                state.currentKeyPointIndex = newIndex
                return .send(.keyPointChanged(shouldPlay: state.isPlaying))
                
            case .skipBackward5SecondsTapped:
                let newTime = max(0, state.currentTime - 5)
                return .send(.audioPlayer(.seek(newTime)))
                
            case .skipForward10SecondsTapped:
                let newTime = min(state.totalDuration, state.currentTime + 10)
                return .send(.audioPlayer(.seek(newTime)))
                
            case let .seekToTime(time):
                return .send(.audioPlayer(.seek(time)))
                
            case .speedButtonTapped:
                let nextSpeed = state.playbackSpeed.next
                return .send(.audioPlayer(.setPlaybackSpeed(nextSpeed)))
                
            case let .keyPointChanged(shouldPlay):
                guard let currentKeyPoint = state.currentKeyPoint else {
                    return .none
                }
                return .send(.audioPlayer(.setTrack(currentKeyPoint.audio, immidiatePlay: shouldPlay)))
                
            case .handlePlaybackFinished:
                guard state.hasNextKeyPoint else { return .none }
                let newIndex = state.currentKeyPointIndex + 1
                state.currentKeyPointIndex = newIndex
                return .send(.keyPointChanged(shouldPlay: true))
                
            case .cleanup:
                return .send(.audioPlayer(.cleanup))
                
            case .cleanupFinished:
                return .none
                
            case .audioPlayer(._playbackStateChanged(.stopped)):
                return .send(.handlePlaybackFinished)
            
            case .audioPlayer(.cleanUpFinished):
                return .send(.cleanupFinished)
                
            case .audioPlayer:
                return .none
            }
        }
        ._printChanges()
    }
}
