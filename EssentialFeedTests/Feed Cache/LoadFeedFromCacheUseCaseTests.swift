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
        expect(
            sut,
            toCompleteWith: .failure(anyNSError),
            when: {
                store.completeRetrieval(with: anyNSError)
            }
        )
    }
    
    func test_load_deliversNoImagesOnEmptyCache() {
        // Given
        let (sut, store) = makeSUT()
        expect(
            sut,
            toCompleteWith: .success([]),
            when: {
                store.completeRetrievalWithEmptyCache()
            }
        )
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
    
    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteWith expectedResult: LocalFeedLoader.LoadResult,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Waiting for complete")
        // When
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
                case (.success(let receivedImages), .success(let expectedImages)):
                    XCTAssertEqual(receivedImages, expectedImages)
                case (.failure(let receivedError as NSError), .failure(let expectedError as NSError)):
                    XCTAssertEqual(receivedError.domain, expectedError.domain)
                    XCTAssertEqual(receivedError.code, expectedError.code)
                default:
                    XCTFail(
                        "Expecting \(expectedResult), got \(receivedResult) instead",
                        file: file,
                        line: line
                    )
            }
            expectation.fulfill()
        }
        action()
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    private var anyNSError: NSError {
        NSError(domain: "anyerror", code: 0)
    }
    
}
