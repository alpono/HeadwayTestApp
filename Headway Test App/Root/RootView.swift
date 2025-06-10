//
//  RootView.swift
//  Headway Test App
//
//  Created by Sashko on 06/06/2025.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct RootAppView: View {
    let store: StoreOf<RootAppFeature>
    
    var body: some View {
        Group {
            if store.showMainApp {
                BooksListView(
                    store: store.scope(
                        state: \.booksList,
                        action: \.booksList
                    )
                )
            } else {
                LoadingScreenView(
                    store: store.scope(
                        state: \.loading,
                        action: \.loading
                    )
                )
            }
        }
    }
}
