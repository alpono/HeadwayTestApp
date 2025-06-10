//
//  BookSummaryTextView.swift
//  Headway Test App
//
//  Created by Sashko on 06/06/2025.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct BookSummaryTextView: View {
    var store: StoreOf<BookSummaryTextFeature>
    let bottomPadding: CGFloat
    var body: some View {
        ScrollView {
            Text(store.summary?.keypoints[store.currentIndex].textTranscription ?? "")
                .padding(EdgeInsets(top: 16, leading: 16, bottom: bottomPadding, trailing: 16))
        }
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    BookSummaryTextView(
        store: Store(initialState: BookSummaryTextFeature.State()) {
            BookSummaryTextFeature()
        }, bottomPadding: 60
    )
}
