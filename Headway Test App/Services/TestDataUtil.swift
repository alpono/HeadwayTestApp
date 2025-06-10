//
//  TestDataUtil.swift
//  Headway Test App
//
//  Created by Sashko on 05/06/2025.
//

import Foundation
import ComposableArchitecture

struct ResourceCopyService: Sendable {
    
    private struct Constants {
        static let booksRootFolderName = "Books"
        static let testResourcesFolderName = "Test data"
    }
    
    var booksFolderURL: URL {
        documentsDirectory.appendingPathComponent(Constants.booksRootFolderName)
    }
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory,
                                in: .userDomainMask).first!
    }
    
    func copyTestResourcesToDocuments() throws {
        guard let bundleURL = Bundle.main.resourceURL else {
            throw ResourceCopyError.bundleResourcesNotFound
        }
        let testResourcesURL = bundleURL.appendingPathComponent(Constants.testResourcesFolderName)
        guard FileManager.default.fileExists(atPath: testResourcesURL.path) else {
            throw ResourceCopyError.testResourcesFolderNotFound
        }
        try createDirectoryIfNeeded(at: booksFolderURL)
        try copyFolder(from: testResourcesURL, to: booksFolderURL)
    }
    
    func testResourcesExistInDocuments() -> Bool {
        FileManager.default.fileExists(atPath: booksFolderURL.path)
    }
    
    private func createDirectoryIfNeeded(at url: URL) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url,
                                          withIntermediateDirectories: true,
                                          attributes: nil)
        }
    }
    
    private func copyFolder(from sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: sourceURL,
                                                          includingPropertiesForKeys: nil)
        for itemURL in contents {
            let destinationItemURL = destinationURL.appendingPathComponent(itemURL.lastPathComponent)
            if fileManager.fileExists(atPath: destinationItemURL.path) {
                try fileManager.removeItem(at: destinationItemURL)
            }
            try fileManager.copyItem(at: itemURL, to: destinationItemURL)
        }
    }
    
}

// MARK: - Error Handling

enum ResourceCopyError: LocalizedError {
    case bundleResourcesNotFound
    case testResourcesFolderNotFound
    case copyFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .bundleResourcesNotFound:
            return "Bundle resources directory not found"
        case .testResourcesFolderNotFound:
            return "Test Resources folder not found in app bundle"
        case .copyFailed(let message):
            return "Failed to copy resources: \(message)"
        }
    }
}

// MARK: - Resource Copy Service Dependency
extension DependencyValues {
    var resourceCopyService: ResourceCopyServiceProtocol {
        get { self[ResourceCopyServiceKey.self] }
        set { self[ResourceCopyServiceKey.self] = newValue }
    }
}

private enum ResourceCopyServiceKey: DependencyKey {
    static let liveValue: ResourceCopyServiceProtocol = LiveResourceCopyService()
}

// MARK: - Resource Copy Service Protocol
protocol ResourceCopyServiceProtocol {
    func copyTestResourcesToDocuments() async throws
    func testResourcesExistInDocuments() async -> Bool
}

// MARK: - Live Resource Copy Service
struct LiveResourceCopyService: ResourceCopyServiceProtocol, Sendable {
    private let service = ResourceCopyService()
    
    func copyTestResourcesToDocuments() async throws {
        try await Task.detached(priority: .userInitiated) {
            try service.copyTestResourcesToDocuments()
        }.value
    }
    
    func testResourcesExistInDocuments() async -> Bool {
        await Task.detached(priority: .userInitiated) {
            service.testResourcesExistInDocuments()
        }.value
    }
}
