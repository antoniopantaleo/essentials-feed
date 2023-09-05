//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 02/09/23.
//

import XCTest
import EssentialFeed

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        // Given
        let (sut, store) = makeSUT()
        let (feed, _) = uniqueImageFeed()
        // When
        sut.save(feed) { _ in }
        // Then
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        // Given
        let (sut, store) = makeSUT()
        let (feed, _) = uniqueImageFeed()
        let deletionError = anyError
        // When
        sut.save(feed) { _ in }
        store.completeDeletion(with: deletionError)
        // Then
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_failsOnDeletionError() {
        // Given
        let (sut, store) = makeSUT()
        let deletionError = anyError
        expect(
            sut,
            toCompleteWithError: deletionError,
            when: {
                store.completeDeletion(with: deletionError)
            }
        )
    }
    
    func test_save_failsOnInsertionError() {
        // Given
        let (sut, store) = makeSUT()
        let insertionError = anyError
        expect(
            sut,
            toCompleteWithError: insertionError,
            when: {
                store.completeDeletionSuccessfully()
                store.completeInsertion(with: insertionError)
            }
        )
    }
    
    func test_save_succeedsOnSuccesfulCacheInsertion() {
        // Given
        let (sut, store) = makeSUT()
        let (feed, _) = uniqueImageFeed()
        let expectation = expectation(description: "Wait for save completion")
        var receivedError: Error?
        // When
        sut.save(feed) { error in
            receivedError = error
            expectation.fulfill()
        }
        store.completeDeletionSuccessfully()
        store.completeInsertionSuccessfully()
        wait(for: [expectation], timeout: 1.0)
        // Then
        XCTAssertNil(receivedError)
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccesfulDeletion() {
        // Given
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let (feed, localFeedItems) = uniqueImageFeed()
        // When
        sut.save(feed) { _ in }
        store.completeDeletionSuccessfully()
        // Then
        XCTAssertEqual(
            store.receivedMessages, [
                .deleteCacheFeed,
                .insert(items: localFeedItems, timestamp: timestamp)
            ]
        )
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTHasBeenDeallocated() {
        // Given
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        var receivedResults = [LocalFeedLoader.SaveResult]()
        let (feed, _) = uniqueImageFeed()
        // When
        sut?.save(feed, completion: { receivedResults.append($0) })
        sut = nil
        store.completeDeletion(with: anyError)
        // Then
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTHasBeenDeallocated() {
        // Given
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        var receivedResults = [LocalFeedLoader.SaveResult]()
        // When
        sut?.save([uniqueImage()], completion: { receivedResults.append($0) })
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyError)
        // Then
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: Helpers
    
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
        toCompleteWithError expectedError: NSError?,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for save completion")
        var receivedError: Error?
        // When
        sut.save([uniqueImage()]) { error in
            receivedError = error
            expectation.fulfill()
        }
        action()
        wait(for: [expectation], timeout: 1.0)
        // Then
        XCTAssertEqual(
            receivedError as? NSError,
            expectedError,
            file: file,
            line: line
        )
    }
    
    private var anyError: NSError {
        NSError(
            domain: "any error",
            code: 0
        )
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
    
    /// This class help us to abstract the framework we are going to use from the tests
    private class FeedStoreSpy: FeedStore {
        
        enum ReceivedMessage: Equatable {
            case deleteCacheFeed
            case insert(items: [LocalFeedImage], timestamp: Date)
        }
        
        private var deletionCompletions: [DeletionCompletion] = []
        private var insertionCompletions: [InsertionCompletion] = []
        
        private(set) var receivedMessages = [ReceivedMessage]()
        
        func deleteChachedFeeds(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCacheFeed)
        }
        
        func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
            receivedMessages.append(.insert(items: items, timestamp: timestamp))
            insertionCompletions.append(completion)
        }
        
        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }
        
        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }
        
        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
        
    }
    
}
