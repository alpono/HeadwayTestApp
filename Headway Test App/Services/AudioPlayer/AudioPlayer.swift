//
//  AudioPlayer.swift
//  Headway Test App
//
//  Created by Sashko on 07/06/2025.
//

//
//  AudioPlayer.swift
//  Headway Test App
//
//  Created by Sashko on 07/06/2025.
//

import Foundation
import AVFoundation

@MainActor
final class AudioPlayer: NSObject, ObservableObject, Sendable {
    
    var currentTrack: AudioTrack?
    var currentTime: TimeInterval {
        audioPlayer?.currentTime ?? 0
    }
    var duration: TimeInterval {
        audioPlayer?.duration ?? 0
    }
    var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }
    
    private var audioPlayer: AVAudioPlayer? {
        didSet {
            setupAudioPlayer()
        }
    }
    private var playbackSpeed: PlaybackSpeed = .normal
    private var timeUpdateTimer: Timer?
    private var timeUpdatesStream: AsyncStream<TimeInterval>?
    private var timeContinuation: AsyncStream<TimeInterval>.Continuation?
    private var stateUpdatesStream: AsyncStream<PlaybackState>?
    private var stateContinuation: AsyncStream<PlaybackState>.Continuation?
    
    nonisolated override init() {
        super.init()
        
        Task { @MainActor in
            setupAudioSession()
            makeNewStreams()
        }
    }
    
    func setTrack(_ track: AudioTrack, play: Bool) async throws {
        stopTimeUpdateTimer()
        stateContinuation?.yield(.loading)
        do {
            let player = try await createAudioPlayer(from: track.url)
            self.audioPlayer = player
            self.currentTrack = track
            
            try? AVAudioSession.sharedInstance().setActive(true)
            
            if play {
                try self.play()
            } else {
                stateContinuation?.yield(.idle)
            }
        } catch {
            let audioError = error as? AudioPlayerError ?? .playbackFailed
            stateContinuation?.yield(.error(audioError))
            throw audioError
        }
    }
    
    func play() throws {
        guard let audioPlayer else {
            throw AudioPlayerError.playerIsNotConfigured
        }
        
        let started = audioPlayer.play()
        if started {
            stateContinuation?.yield(.playing)
            startTimeUpdateTimer()
        } else {
            let error = AudioPlayerError.playbackFailed
            stateContinuation?.yield(.error(error))
            throw error
        }
    }
    
    func pause() throws {
        guard let audioPlayer else {
            throw AudioPlayerError.playerIsNotConfigured
        }
        
        audioPlayer.pause()
        stateContinuation?.yield(.paused)
        stopTimeUpdateTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        stateContinuation?.yield(.idle)
        stopTimeUpdateTimer()
        audioPlayer?.currentTime = 0
    }
    
    func seek(to time: TimeInterval) {
        guard let audioPlayer else { return }
        
        let newTime = max(0, min(time, audioPlayer.duration))
        audioPlayer.currentTime = newTime
        timeContinuation?.yield(newTime)
    }
    
    func setPlaybackSpeed(_ speed: PlaybackSpeed) {
        self.playbackSpeed = speed
        audioPlayer?.rate = speed.value
        
        // Restart timer with appropriate interval for the new speed
        if isPlaying {
            startTimeUpdateTimer()
        }
    }
    
    func getTimeUpdates() -> AsyncStream<TimeInterval> {
        timeUpdatesStream ?? makeTimeUpdatesStream()
    }
    
    func getPlaybackStateChanges() -> AsyncStream<PlaybackState> {
        stateUpdatesStream ?? makeStateUpdatesStream()
    }
    
    func cleanup() {
        stop()
        playbackSpeed = .normal
        audioPlayer = nil
        currentTrack = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        
        timeContinuation?.finish()
        timeContinuation = nil
        timeUpdatesStream = nil
        
        stateContinuation?.finish()
        stateContinuation = nil
        stateUpdatesStream = nil
    }
    
    private func makeNewStreams() {
        makeTimeUpdatesStream()
        makeStateUpdatesStream()
    }
    
    @discardableResult
    private func makeTimeUpdatesStream() -> AsyncStream<TimeInterval> {
        let timeStreamTuple = AsyncStream.makeStream(of: TimeInterval.self)
        timeUpdatesStream = timeStreamTuple.stream
        timeContinuation = timeStreamTuple.continuation
        timeStreamTuple.continuation.onTermination = { _ in
            print("")
        }
        return timeStreamTuple.stream
    }
    
    @discardableResult
    private func makeStateUpdatesStream() -> AsyncStream<PlaybackState> {
        let stateStreamTuple = AsyncStream.makeStream(of: PlaybackState.self)
        stateUpdatesStream = stateStreamTuple.stream
        stateContinuation = stateStreamTuple.continuation
        stateStreamTuple.continuation.onTermination = { _ in
            print("")
        }
        return stateStreamTuple.stream
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func createAudioPlayer(from url: URL) async throws -> AVAudioPlayer {
        try await Task.detached(priority: .userInitiated) {
            try AVAudioPlayer(contentsOf: url)
        }.value
    }
    
    private func setupAudioPlayer() {
        guard let audioPlayer else { return }
        
        audioPlayer.rate = playbackSpeed.value
        audioPlayer.enableRate = true
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
    }
    
    private func startTimeUpdateTimer() {
        stopTimeUpdateTimer()
        
        // Adjust timer interval based on playback speed for smoother updates
        let interval = max(0.1, 0.5 / Double(playbackSpeed.value))
        
        timeUpdateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let audioPlayer else { return }
                timeContinuation?.yield(audioPlayer.currentTime)
            }
        }
    }
    
    private func stopTimeUpdateTimer() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = nil
    }
    
    deinit {
        Task { @MainActor [timeUpdateTimer] in
            timeUpdateTimer?.invalidate()
        }
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            if flag, let currentTrack {
                timeContinuation?.yield(currentTrack.duration)
            }
            stateContinuation?.yield(flag ? .stopped : .error(.playbackFailed))
            stopTimeUpdateTimer()
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            stateContinuation?.yield(.error(.playbackFailed))
            stopTimeUpdateTimer()
        }
    }
}
