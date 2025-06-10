//
//  ResourcesPreparationView.swift
//  Headway Test App
//
//  Created by Sashko on 06/06/2025.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct LoadingScreenView: View {
    let store: StoreOf<LoadingFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(viewStore.isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0), value: viewStore.isAnimating)
                    
                    Text("Headway Test App")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Loading Content
                    VStack(spacing: 16) {
                        if viewStore.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        }
                        Text(viewStore.statusMessage)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Error Message (if any)
                        if viewStore.hasError {
                            VStack(spacing: 12) {
                                Text(viewStore.errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button("Retry") {
                                    viewStore.send(.retryButtonTapped)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .frame(minHeight: 100)
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}
