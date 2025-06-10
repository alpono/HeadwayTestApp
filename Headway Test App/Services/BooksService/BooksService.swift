//
//  BooksService.swift
//  Headway Test App
//
//  Created by Sashko on 05/06/2025.
//

import Foundation
import ComposableArchitecture

// MARK: - Internal JSON Models
private struct BookMetadata: Codable, Sendable {
    let id: Int
    let name: String
    let image: String
    let keypoints: [KeyPoint]
}

private struct KeyPoint: Codable, Sendable {
    let title: String
    let file: String
    let duration: Int
    let text: String
}

protocol BookDataManagerProtocol {
    func fetchBooksList() async throws -> [BookSummaryListItem]
    func fetchBookDetails(by id: Int) async throws -> BookSummary
}

// MARK: - BookDataManager
final class BookDataManager: BookDataManagerProtocol, Sendable {
    private let testDataFolderURL: URL
    
    init(testDataFolderURL: URL) {
        self.testDataFolderURL = testDataFolderURL
    }
    
    // MARK: - Public Interface
    
    func fetchBooksList() async throws -> [BookSummaryListItem] {
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached { [testDataFolderURL] in
                do {
                    let books = try await self.scanAndLoadBooksList(from: testDataFolderURL)
                    continuation.resume(returning: books)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchBookDetails(by id: Int) async throws -> BookSummary {
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached { [testDataFolderURL] in
                do {
                    let bookSummary = try await self.scanAndLoadBookDetails(id: id, from: testDataFolderURL)
                    continuation.resume(returning: bookSummary)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func scanAndLoadBooksList(from folderURL: URL) async throws -> [BookSummaryListItem] {
        let fileManager = FileManager.default
        
        let bookFolders = try fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        var books: [BookSummaryListItem] = []
        
        for bookFolderURL in bookFolders {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: bookFolderURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                continue
            }
            
            let dataJSONURL = bookFolderURL.appendingPathComponent("data.json")
            guard fileManager.fileExists(atPath: dataJSONURL.path) else {
                print("Warning: data.json not found in \(bookFolderURL.lastPathComponent)")
                continue
            }
            
            do {
                let jsonData = try Data(contentsOf: dataJSONURL)
                let bookMetadata = try JSONDecoder().decode(BookMetadata.self, from: jsonData)
                
                let imageURL = bookFolderURL.appendingPathComponent(bookMetadata.image)
                
                let bookItem = BookSummaryListItem(
                    title: bookMetadata.name,
                    image: imageURL,
                    id: bookMetadata.id
                )
                
                books.append(bookItem)
                
            } catch {
                print("Error parsing JSON for \(bookFolderURL.lastPathComponent): \(error)")
            }
        }
        
        // Sort books by ID for consistent ordering
        return books.sorted { $0.id < $1.id }
    }
    
    private func scanAndLoadBookDetails(id: Int, from folderURL: URL) async throws -> BookSummary {
        let fileManager = FileManager.default
        
        let bookFolders = try fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        for bookFolderURL in bookFolders {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: bookFolderURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                continue
            }
            
            let dataJSONURL = bookFolderURL.appendingPathComponent("data.json")
            guard fileManager.fileExists(atPath: dataJSONURL.path) else {
                continue
            }
            
            do {
                let jsonData = try Data(contentsOf: dataJSONURL)
                let bookMetadata = try JSONDecoder().decode(BookMetadata.self, from: jsonData)
                
                // Check if this is the book we're looking for
                guard bookMetadata.id == id else { continue }
                
                let imageURL = await findImageFile(baseName: bookMetadata.image, in: bookFolderURL)
                    ?? bookFolderURL.appendingPathComponent(bookMetadata.image)
                
                let keypoints = bookMetadata.keypoints.enumerated().map { index, keypoint in
                    let audioURL = bookFolderURL.appendingPathComponent(keypoint.file)
                    let audioTrack = AudioTrack(url: audioURL, duration: TimeInterval(keypoint.duration))
                    
                    return BookSummaryKeyPoint(
                        audio: audioTrack,
                        title: keypoint.title,
                        textTranscription: keypoint.text,
                        index: UInt(index),
                        id: UInt(id * 1000 + index) // Generate unique ID
                    )
                }
                
                return BookSummary(
                    image: imageURL,
                    keypoints: keypoints
                )
                
            } catch {
                print("Error parsing JSON for \(bookFolderURL.lastPathComponent): \(error)")
            }
        }
        
        throw BookDataError.bookNotFound(id: id)
    }
    
    private func findImageFile(baseName: String, in folderURL: URL) async -> URL? {
        let possibleExtensions = ["jpg", "jpeg", "png", "JPG", "JPEG", "PNG"]
        let fileManager = FileManager.default
        
        for ext in possibleExtensions {
            let imageURL = folderURL.appendingPathComponent("\(baseName).\(ext)")
            if fileManager.fileExists(atPath: imageURL.path) {
                return imageURL
            }
        }
        
        return nil
    }
}

// MARK: - Error Types
enum BookDataError: Error, LocalizedError, Sendable {
    case bookNotFound(id: Int)
    case failedToScanDirectory(Error)
    
    var errorDescription: String? {
        switch self {
        case .bookNotFound(let id):
            return "Book with ID \(id) not found"
        case .failedToScanDirectory(let error):
            return "Failed to scan directory: \(error.localizedDescription)"
        }
    }
}

// MARK: - Dependency
extension DependencyValues {
    var bookDataManager: BookDataManagerProtocol {
        get { self[BookDataManagerKey.self] }
        set { self[BookDataManagerKey.self] = newValue }
    }
}

private enum BookDataManagerKey: DependencyKey {
    static let liveValue: BookDataManagerProtocol = {
        return BookDataManager(testDataFolderURL: ResourceCopyService().booksFolderURL)
    }()
}
