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
        let feed: [LocalFeedImage]
        let timestamp: Date
    }
    
    private let storeURL = FileManager
        .default
        .urls(for: .documentDirectory, in: .userDomainMask)
        .first!
        .appending(path: "image-feed.store", directoryHint: .notDirectory)
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(Cache(feed: feed, timestamp: timestamp))
        try! encoded.write(to:  storeURL)
        completion(nil)
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.feed, timestamp: cache.timestamp))
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
