//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 24/09/23.
//

import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    
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
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
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
    
    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().localFeedItems
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        expect(sut, toRetrieve: .empty)
    }
    
    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        var completedOperationsInOrder = [XCTestExpectation]()
        let operation1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().localFeedItems, timestamp: Date()) { _ in
            completedOperationsInOrder.append(operation1)
            operation1.fulfill()
        }
        
        let operation2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(operation2)
            operation2.fulfill()
        }
        
        let operation3 = expectation(description: "Operation 3")
        sut.insert(uniqueImageFeed().localFeedItems, timestamp: Date()) { _ in
            completedOperationsInOrder.append(operation3)
            operation3.fulfill()
        }
        
        wait(for: [operation1, operation2, operation3], timeout: 1.0)
        XCTAssertEqual(completedOperationsInOrder, [operation1, operation2, operation3], "Expected side-effects to run serially but operations finished in the wrong order")
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

}
