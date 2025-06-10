//
//  BooksListFeature.swift
//  Headway Test App
//
//  Created by Sashko on 05/06/2025.
//

import Foundation
import ComposableArchitecture

@Reducer
struct BooksListFeature: Sendable {
    
    @ObservableState
    struct State: Equatable, Sendable {
        @Presents var bookSummary: BookSummaryFeature.State?
        var books: [BookSummaryListItem] = []
        var isLoading = false
        var errorMessage: String?
        var selectedBookId: Int?
        var hasError: Bool {
            errorMessage != nil
        }
        var isShowingBookDetails: Bool {
            bookSummary != nil
        }
    }
    
    enum Action: Sendable {
        case onAppear
        case booksResponse(Result<[BookSummaryListItem], Error>)
        case dismissError
        case bookTapped(BookSummaryListItem)
        case bookSummary(BookSummaryFeature.Action)
        case dismissBookSummary
    }
    
    @Dependency(\.bookDataManager) var bookDataManager
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.books.isEmpty && !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    await send(.booksResponse(Result { try await bookDataManager.fetchBooksList() }))
                }
                
            case let .booksResponse(.success(books)):
                state.isLoading = false
                state.books = books
                state.errorMessage = nil
                return .none
                
            case let .booksResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
                
            case .dismissBookSummary:
                state.bookSummary = nil
                state.selectedBookId = nil
                return .none
                
            case let .bookTapped(book):
                state.selectedBookId = book.id
                state.bookSummary = BookSummaryFeature.State(bookId: book.id)
                return .none
                
            case .bookSummary(.dismissCleanupFinished):
                state.bookSummary = nil
                state.selectedBookId = nil
                return .none
                
            case .bookSummary:
                return .none    
            }
        }
        .ifLet(\.bookSummary, action: \.bookSummary) { BookSummaryFeature() }
        ._printChanges()
    }
    
}
