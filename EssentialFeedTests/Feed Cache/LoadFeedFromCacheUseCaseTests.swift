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
        let (sut, store) = makeSUT()
        expect(
            sut,
            toCompleteWith: .success([]),
            when: {
                store.completeRetrievalWithEmptyCache()
            }
        )
    }
    
    func test_load_deliversCachedImagesOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        expect(
            sut,
            toCompleteWith: .success(feed.items),
            when: {
                store.completeRetrieval(with: feed.localFeedItems, timestamp: lessThanSevenDaysOldTimestamp)
            }
        )
    }
    
    func test_load_deliversNoImagesOnSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        expect(
            sut,
            toCompleteWith: .success([]),
            when: {
                store.completeRetrieval(with: feed.localFeedItems, timestamp: sevenDaysOldTimestamp)
            }
        )
    }
    
    func test_load_deliversNoImagesOnMoreThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        expect(
            sut,
            toCompleteWith: .success([]),
            when: {
                store.completeRetrieval(with: feed.localFeedItems, timestamp: sevenDaysOldTimestamp)
            }
        )
    }
    
    func test_load_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        sut.load { _ in }
        store.completeRetrieval(with: anyNSError)
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func test_load_doesNotDeletesCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()
        XCTAssertEqual(store.receivedMessages, [.retrieve])
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
    
    private func uniqueImage() -> FeedImage {
        FeedImage(
            id: UUID(),
            description: "any description",
            location: "any location",
            url: URL(string: "https://any-url.com")!
        )
    }
    
    private func uniqueImageFeed() -> (items: [FeedImage], localFeedItems: [LocalFeedImage]) {
        let items = [uniqueImage(), uniqueImage()]
        let localFeedItems = items.map {
            LocalFeedImage(
                id: $0.id,
                description: $0.description,
                location: $0.location,
                url: $0.url
            )
        }
        return (items, localFeedItems)
    }
    
    private var anyNSError: NSError {
        NSError(domain: "anyerror", code: 0)
    }
    
}

fileprivate extension Date {
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
