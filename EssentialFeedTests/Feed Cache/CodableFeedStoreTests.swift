//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 24/09/23.
//

import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().localFeedItems
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().localFeedItems
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() throws {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        try "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyNSError))
    }
    
    func test_retrieve_hasNoSideEffectsOnRetrievalError() throws {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        try "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyNSError))
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        let firstFeed = uniqueImageFeed().localFeedItems
        let firstTimestamp = Date()
       
        let firstInsertionError = insert((firstFeed, firstTimestamp), to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")
        
        let latestFeed = uniqueImageFeed().localFeedItems
        let latestTimestamp = Date()
        let latestInsertionError = insert((latestFeed, latestTimestamp), to: sut)
        XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
        
        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().localFeedItems
        let timestamp = Date()
        
        let insertionError = insert((feed, timestamp), to: sut)
        
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
    }
    
    // MARK: Helpers
    
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> any FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL)
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private var testSpecificStoreURL: URL {
        FileManager
            .default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first!
            .appending(path: "\(type(of: self)).store", directoryHint: .notDirectory)
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
    
    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: any FeedStore) -> Error?{
        let expectation = expectation(description: "Wait for cache insertion")
        var receivedError: Error? = nil
        sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
            receivedError = insertionError
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        return receivedError
    }
    
    private func expect(
        _ sut: any FeedStore,
        toRetrieve expectedResult: RetrieveCahedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for completion")
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
                case (.empty, .empty), (.failure, .failure):
                    break
                case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                    XCTAssertEqual(expectedFeed, retrievedFeed, file: file, line: line)
                    XCTAssertEqual(expectedTimestamp, retrievedTimestamp, file: file, line: line)
                default:
                    XCTFail(
                        "Expected to retrieve \(expectedResult), got \(retrievedResult) instead",
                        file: file,
                        line: line
                    )
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    private func expect(
        _ sut: any FeedStore,
        toRetrieveTwice expectedResult: RetrieveCahedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

}
