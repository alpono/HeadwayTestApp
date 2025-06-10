 //
//  Headway_Test_App.swift
//  Headway Test App
//
//  Created by Sashko on 05/06/2025.
//

import SwiftUI
import ComposableArchitecture

@main
struct HeadwayTestApp: App {
    var body: some Scene {
        WindowGroup {
            RootAppView(
                store: Store(initialState: RootAppFeature.State()) {
                    RootAppFeature()
                }
            )
        }
    }
}
