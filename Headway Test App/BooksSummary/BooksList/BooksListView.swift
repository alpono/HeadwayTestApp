//
//  BooksListView.swift
//  Headway Test App
//
//  Created by Sashko on 06/06/2025.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct BooksListView: View {
    @Bindable var store: StoreOf<BooksListFeature>
    
    var body: some View {
        NavigationView {
            ZStack {
                if store.isLoading && store.books.isEmpty {
                    loadingView
                } else {
                    booksListView
                }
            }
            .navigationTitle("Books")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                store.send(.onAppear)
            }
            .alert(
                "Error",
                isPresented: .constant(store.hasError),
                actions: {
                    Button("OK") {
                        store.send(.dismissError)
                    }
                },
                message: {
                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                    }
                }
            )
            .fullScreenCover(
                isPresented: Binding(
                    get: { store.isShowingBookDetails },
                    set: { _ in store.send(.dismissBookSummary) }
                )
            ) {
                IfLetStore(store.scope(state: \.bookSummary, action: \.bookSummary)) { bookSummaryStore in
                    NavigationView {
                        BookSummaryView(store: bookSummaryStore)
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading books...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var booksListView: some View {
        Group {
            if store.books.isEmpty && !store.isLoading {
                emptyStateView
            } else {
                List(store.books, id: \.id) { book in
                    BookRowView(book: book) {
                        store.send(.bookTapped(book))
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Books Found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Make sure your Test data folder contains book folders with data.json files")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
}

struct BookRowView: View {
    let book: BookSummaryListItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                AsyncImage(url: book.image) { image in
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
                .frame(width: 60, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BooksListView(
        store: Store(
            initialState: BooksListFeature.State()
        ) {
            BooksListFeature()
        }
    )
}
