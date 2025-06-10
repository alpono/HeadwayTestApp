//
//  RootFeature.swift
//  Headway Test App
//
//  Created by Sashko on 06/06/2025.
//

import Foundation
import ComposableArchitecture

@Reducer
struct RootAppFeature: Sendable {
    
    @ObservableState
    struct State: Equatable, Sendable {
        var showMainApp = false
        var loading = LoadingFeature.State()
        var booksList = BooksListFeature.State()
    }
    
    enum Action: Sendable {
        case loading(LoadingFeature.Action)
        case booksList(BooksListFeature.Action)
        case showMainAppChanged(Bool)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.loading, action: \.loading) {
            LoadingFeature()
        }
        
        Scope(state: \.booksList, action: \.booksList) {
            BooksListFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .loading(.resourcePreparationCompleted):
                return .send(.showMainAppChanged(true))
                
            case let .showMainAppChanged(show):
                state.showMainApp = show
                return .none
                
            case .loading:
                return .none
                
            case .booksList:
                return .none
            }
        }
    }
}
