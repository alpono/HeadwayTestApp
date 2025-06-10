//
//  BookSummary.swift
//  Headway Test App
//
//  Created by Sashko on 03/06/2025.
//

import Foundation
import ComposableArchitecture

@Reducer
struct BookSummaryFeature: Sendable {
    
    @ObservableState
    struct State: Equatable, Sendable {
        let bookId: Int
        var bookSummary: BookSummary? = nil
        var failedToLoadSummary = false
        var isLoading = false
        var keypointIndex = 0
        var summaryFormat = SummaryFormat.audio
        var segmentedControlHeight: CGFloat = 0
        var audioPlayerState = BookSummaryPlayerFeature.State()
        var textPresentationState = BookSummaryTextFeature.State()
    }
    
    enum Action: Equatable, Sendable {
        case onAppear
        case loadSummary(Int)
        case summaryLoaded(BookSummary)
        case summaryLoadingFailed
        case retryLoadingSummaryTapped
        case formatChanged(SummaryFormat)
        case dismiss
        case dismissCleanupFinished
        case audioPlayer(BookSummaryPlayerFeature.Action)
        case textPresentation(BookSummaryTextFeature.Action)
    }
    
    @Dependency(\.bookDataManager) var bookDataManager
    
    var body: some ReducerOf<Self> {
        Scope(state: \.audioPlayerState, action: \.audioPlayer) {
            BookSummaryPlayerFeature()
        }
        
        Scope(state: \.textPresentationState, action: \.textPresentation) {
            BookSummaryTextFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadSummary(state.bookId))
                
            case .retryLoadingSummaryTapped:
                return .send(.loadSummary(state.bookId))
                
            case let .loadSummary(bookId):
                state.isLoading = true
                return .run { send in
                    do {
                        let summary = try await bookDataManager.fetchBookDetails(by: bookId)
                        await send(.summaryLoaded(summary))
                    } catch {
                        await send(.summaryLoadingFailed)
                    }
                }
                
            case let .summaryLoaded(summary):
                state.isLoading = false
                state.failedToLoadSummary = false
                state.bookSummary = summary
                return .merge(
                    .send(.audioPlayer(.setSummary(summary))),
                    .send(.textPresentation(.setSummary(summary)))
                )
            case .summaryLoadingFailed:
                state.failedToLoadSummary = true
                state.isLoading = false
                return .none
                
            case let .formatChanged(format):
                state.summaryFormat = format
                return .none
                
            case .audioPlayer(.keyPointChanged):
                let newIndex = state.audioPlayerState.currentKeyPointIndex
                state.keypointIndex = newIndex
                return .send(.textPresentation(.setKeypointIndex(newIndex)))
            
            case .dismiss:
                return .send(.audioPlayer(.cleanup))
                
            case .dismissCleanupFinished:
                return .none
                
            case .audioPlayer(.cleanupFinished):
                return .send(.dismissCleanupFinished)
                
            case .audioPlayer:
                return .none
                
            case .textPresentation:
                return .none
            }
            
        }
        ._printChanges()
    }
}
