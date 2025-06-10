//
//  BookSummaryText.swift
//  Headway Test App
//
//  Created by Sashko on 03/06/2025.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct BookSummaryTextFeature: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var summary: BookSummary?
        var currentIndex: Int = 0
    }
    
    enum Action: Equatable, Sendable {
        case setKeypointIndex(Int)
        case setSummary(BookSummary)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .setSummary(let summary):
                state.summary = summary
                state.currentIndex = 0
                return .none
            case .setKeypointIndex(let index):
                state.currentIndex = index
                return .none
            }
        }
        ._printChanges()
    }
}


