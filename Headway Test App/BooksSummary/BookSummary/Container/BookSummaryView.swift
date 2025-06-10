//
//  BookSummaryAudioPlayerView.swift
//  Headway Test App
//
//  Created by Sashko on 06/06/2025.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct BookSummaryView: View {
    
    @Bindable var store: StoreOf<BookSummaryFeature>
    @State private var segmentedControlHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            contentView
        }
        .background(Color(red: 254/255, green: 249/255, blue: 244/255))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    store.send(.dismiss)
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if store.isLoading {
            loadingView
        } else if store.failedToLoadSummary {
            errorView
        } else {
            featureContentView
        }
    }
    
    private var featureContentView: some View {
        Group {
            segmentedContentView
            segmentedControlOverlay
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Summary...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Failed to Load Summary")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("We couldn't load the book summary. Please check your connection and try again.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            Button("Try Again") {
                store.send(.retryLoadingSummaryTapped)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var segmentedContentView: some View {
        switch store.summaryFormat {
        case .audio:
            BookSummaryPlayerView(
                store: store.scope(
                    state: \.audioPlayerState,
                    action: \.audioPlayer
                )
            )
            .padding(.bottom, segmentedControlHeight + 16)
        case .text:
            BookSummaryTextView(
                store: store.scope(
                    state: \.textPresentationState,
                    action: \.textPresentation
                ),
                bottomPadding: segmentedControlHeight + 8
            )
        }
    }
    
    private var segmentedControlOverlay: some View {
        VStack {
            Spacer()
            playerSegmentedControlView
                .padding(.bottom, 16)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                segmentedControlHeight = geometry.size.height
                            }
                            .onChange(of: geometry.size.height) { _, newHeight in
                                segmentedControlHeight = newHeight
                            }
                    }
                )
        }
    }
    
    private var playerSegmentedControlView: some View {
        ZStack(alignment: alignment(for: store.summaryFormat)) {
            Circle()
                .fill(.blue)
                .frame(width: 50, height: 50)
            HStack(spacing: 0) {
                ForEach(SummaryFormat.allCases, id: \.self) { type in
                    segmentButton(for: type)
                }
            }
        }
        .padding(3)
        .background(Color.white)
        .cornerRadius(28)
    }
    
    private func segmentButton(for type: SummaryFormat) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                _ = store.send(.formatChanged(type))
            }
        } label: {
            Image(systemName: type.iconName)
                .frame(width: 50, height: 50)
                .font(.title3)
                .foregroundColor(store.summaryFormat == type ? .white : .primary)
        }
    }
    
    private func alignment(for format: SummaryFormat) -> Alignment {
        switch format {
        case .audio: return .leading
        case .text: return .trailing
        }
    }
    
}

#Preview {
    BookSummaryView(
        store: Store(initialState: BookSummaryFeature.State(bookId: 1)) {
            BookSummaryFeature()
                ._printChanges()
        }
    )
}
