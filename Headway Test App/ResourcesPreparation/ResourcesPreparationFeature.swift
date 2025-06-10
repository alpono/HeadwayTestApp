//
//  LoadingFeature.swift
//  Headway Test App
//
//  Created by Sashko on 05/06/2025.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct LoadingFeature {
    @ObservableState
    struct State: Equatable {
        var isLoading = false
        var isAnimating = false
        var statusMessage = "Initializing..."
        var errorMessage = ""
        var isComplete = false
        var hasError: Bool {
            !errorMessage.isEmpty
        }
    }
    
    enum Action {
        case onAppear
        case startResourcePreparation
        case resourcePreparationStarted
        case statusUpdated(String)
        case resourcesAlreadyExist
        case resourcesCopied
        case resourcePreparationCompleted
        case resourcePreparationFailed(String)
        case retryButtonTapped
        case animationToggled
    }
    
    @Dependency(\.resourceCopyService) var resourceCopyService
    @Dependency(\.continuousClock) var clock
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isAnimating = true
                return .run { send in
                    // Start the pulsing animation
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.animationToggled)
                    }
                }
                .merge(with: .send(.startResourcePreparation))
                
            case .startResourcePreparation:
                state.isLoading = true
                state.errorMessage = ""
                state.statusMessage = "Preparing resources..."
                return .send(.resourcePreparationStarted)
                
            case .resourcePreparationStarted:
                return .run { send in
                    do {
                        await send(.statusUpdated("Checking existing resources..."))
                        
                        if await resourceCopyService.testResourcesExistInDocuments() {
                            await send(.statusUpdated("Resources already available"))
                            try await clock.sleep(for: .milliseconds(500))
                            await send(.resourcesAlreadyExist)
                        } else {
                            await send(.statusUpdated("Copying test resources..."))
                            try await resourceCopyService.copyTestResourcesToDocuments()
                            await send(.statusUpdated("Resources copied successfully"))
                            try await clock.sleep(for: .milliseconds(500))
                            await send(.resourcesCopied)
                        }
                        
                        await send(.statusUpdated("Ready to start!"))
                        try await clock.sleep(for: .seconds(1))
                        await send(.resourcePreparationCompleted)
                        
                    } catch {
                        await send(.resourcePreparationFailed(error.localizedDescription))
                    }
                }
                
            case let .statusUpdated(message):
                state.statusMessage = message
                return .none
                
            case .resourcesAlreadyExist, .resourcesCopied:
                return .none
                
            case .resourcePreparationCompleted:
                state.isLoading = false
                state.isComplete = true
                return .none
                
            case let .resourcePreparationFailed(errorMessage):
                state.isLoading = false
                state.errorMessage = errorMessage
                state.statusMessage = "Failed to prepare resources"
                return .none
                
            case .retryButtonTapped:
                return .send(.startResourcePreparation)
                
            case .animationToggled:
                state.isAnimating.toggle()
                return .none
            }
        }
    }
}
