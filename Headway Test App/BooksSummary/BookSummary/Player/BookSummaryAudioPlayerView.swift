//
//  BookSummaryAudioPlayerView.swift
//  Headway Test App
//
//  Created by Sashko on 06/06/2025.
//
import Foundation
import SwiftUI
import ComposableArchitecture

struct BookSummaryPlayerView: View {
    @Bindable var store: StoreOf<BookSummaryPlayerFeature>
    
    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geo in
                let size = sizeFits(size: geo.size)
                bookCoverView
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(16)
                    .position(x: geo.size.width / 2, y: size.height / 2)
            }
            keypointView
            playbackProgressView
            playbackSpeedView
            playbackControls
        }
        .background(Color(red: 254/255, green: 249/255, blue: 244/255))
    }
    
    private var playbackSpeedView: some View {
        Button {
            store.send(.speedButtonTapped)
        } label: {
            Text("Speed x\(String(format: "%.2g", store.playbackSpeed.value))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(8)
        .background(.gray.opacity(0.3))
        .cornerRadius(8)
    }
    
    private var keypointView: some View {
        VStack(spacing: 16) {
            Text(store.keyPointProgress)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .tracking(1)
            
            Text(store.currentKeyPoint?.title ?? "")
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 50)
                .padding(.horizontal, 32)
        }
        .padding(.top, 40)
    }
    
    private var bookCoverView: some View {
        AsyncImage(url: store.bookSummary?.image) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .overlay {
                    Image(systemName: "book.closed")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
        }
    }
    
    private var playbackProgressView: some View {
        VStack(spacing: 24) {
            HStack {
                Text(formatTime(store.currentTime))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: 40)
                
                Slider(
                    value: .init(
                        get: { store.currentTime },
                        set: { store.send(.seekToTime($0)) }
                    ),
                    in: 0...store.totalDuration
                )
                .accentColor(.blue)
                .disabled(store.isLoading)
                
                Text(formatTime(store.totalDuration))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: 40)
            }
        }
        .padding(.horizontal, 32)
    }
    
    private var playbackControls: some View {
        HStack(spacing: 30) {
            Button {
                store.send(.previousKeyPointTapped)
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.title2)
                    .foregroundColor(store.hasPreviousKeyPoint ? .primary : .gray)
            }
            .disabled(!store.hasPreviousKeyPoint)
            
            Button {
                store.send(.skipBackward5SecondsTapped)
            } label: {
                Image(systemName: "gobackward.5")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            playPauseButton
            
            Button {
                store.send(.skipForward10SecondsTapped)
            } label: {
                Image(systemName: "goforward.10")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Button {
                store.send(.nextKeyPointTapped)
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .foregroundColor(store.hasNextKeyPoint ? .primary : .gray)
            }
            .disabled(!store.hasNextKeyPoint)
        }
    }
    
    private var playPauseButton: some View {
        Button {
            store.send(.playPauseButtonTapped)
        } label: {
            ZStack {
                if store.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                }
            }
        }
        .frame(width: 60, height: 60)
        .buttonStyle(
            CircularPressedButtonStyle(
                selectedColor: .gray,
                unselectedColor: .clear,
                foregroundColor: .black,
                padding: 12
            )
        )
        .disabled(store.currentKeyPoint == nil)
    }
    
    // MARK: - Helper Methods
    
    private func sizeFits(size: CGSize) -> CGSize {
        let widthRatio = 0.55
        let aspectRatio: CGFloat = 1.5
        var width = size.width * widthRatio
        var height = width * aspectRatio
        if height > size.height {
            height = size.height
            width = height / aspectRatio
        }
        return .init(width: width, height: height)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
}

struct CircularPressedButtonStyle: ButtonStyle {
    private let selectedColor: Color
    private let unselectedColor: Color
    private let padding: CGFloat
    private let foregroundColor: Color
    
    init(
        selectedColor: Color,
        unselectedColor: Color,
        foregroundColor: Color,
        padding: CGFloat
    ) {
        self.selectedColor = selectedColor
        self.unselectedColor = unselectedColor
        self.padding = padding
        self.foregroundColor = foregroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding(padding)
            .background(
                Circle()
                    .fill(configuration.isPressed ? selectedColor : unselectedColor)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    BookSummaryPlayerView(
        store: Store(initialState: BookSummaryPlayerFeature.State()) {
            BookSummaryPlayerFeature()
                ._printChanges()
        }
    )
}
