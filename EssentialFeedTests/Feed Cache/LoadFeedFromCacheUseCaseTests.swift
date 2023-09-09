//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Antonio on 09/09/23.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestsCacheRetrieval() {
        // Given
        let (sut, store) = makeSUT()
        // When
        sut.load { _ in }
        // Then
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnCacheRetrieval() {
        // Given
        let (sut, store) = makeSUT()
        let expectation = expectation(description: "Waiting for complete")
        var receivedError: Error?
        // When
        sut.load { result in
            guard case let .failure(error) = result else {
                return XCTFail("Expecting to receive a failure")
            }
            receivedError = error
            expectation.fulfill()
        }
        store.completeRetrieval(with: anyNSError)
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, anyNSError)
    }
    
    //MARK: Helpers
    
    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private var anyNSError: NSError {
        NSError(domain: "anyerror", code: 0)
    }
    
}
