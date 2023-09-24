//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 24/09/23.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    
    private struct Cache: Codable {
        let feed: [CodableLocalFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map { $0.localFeedImage }
        }
    }
    
    private struct CodableLocalFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var localFeedImage: LocalFeedImage {
            LocalFeedImage(
                id: id,
                description: description,
                location: location,
                url: url
            )
        }
    }
    
    private let storeURL = FileManager
        .default
        .urls(for: .documentDirectory, in: .userDomainMask)
        .first!
        .appending(path: "image-feed.store", directoryHint: .notDirectory)
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableLocalFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to:  storeURL)
        completion(nil)
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
    }
    
}

final class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        let storeURL = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appending(path: "image-feed.store", directoryHint: .notDirectory)
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    override func tearDown() {
        let storeURL = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appending(path: "image-feed.store", directoryHint: .notDirectory)
        try? FileManager.default.removeItem(at: storeURL)
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "Wait for completion")
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                return XCTFail("Expected empty result, got \(result) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "Wait for completion")
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    return XCTFail("Expected empty result, got \(firstResult) and \(secondResult) instead")
                }
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = CodableFeedStore()
        let feed = uniqueImageFeed().localFeedItems
        let timestamp = Date()
        let expectation = expectation(description: "Wait for completion")
        sut.insert(feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            sut.retrieve { retrieveResult in
                switch retrieveResult {
                case .found(let retrievedFeed, let retrievedTimestamp):
                    XCTAssertEqual(feed, retrievedFeed)
                    XCTAssertEqual(timestamp, retrievedTimestamp)
                default:
                    return XCTFail("Expected found result with \(feed) and \(timestamp), got \(retrieveResult) instead")
                }
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

}
