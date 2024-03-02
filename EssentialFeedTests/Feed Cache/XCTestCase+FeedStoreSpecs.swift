//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Antonio on 01/10/23.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    
    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: any FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: any FeedStore) -> Error?{
        let expectation = expectation(description: "Wait for cache insertion")
        var receivedError: Error? = nil
        sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
            receivedError = insertionError
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        return receivedError
    }
    
    @discardableResult
    func deleteCache(from sut: any FeedStore) -> Error? {
        let expectation = expectation(description: "Waiting for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { error in
            deletionError = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        return deletionError
    }
    
    func expect(
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
    
    func expect(
        _ sut: any FeedStore,
        toRetrieveTwice expectedResult: RetrieveCahedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
}
