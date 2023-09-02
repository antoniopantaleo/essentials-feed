//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 02/09/23.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    private var store: FeedStore
    private var currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteChachedFeeds { [unowned self] error in
            if error == nil {
                store.insert(items, timestamp: self.currentDate())
            }
        }
    }
}

/// This class help us to abstract the framework we are going to use from the tests
class FeedStore {
    typealias DeletionCompletion = ((Error?) -> Void)
    
    enum ReceivedMessage: Equatable {
        case deleteCacheFeed
        case insert(items: [FeedItem], timestamp: Date)
    }
    
    private var deletionCompletions: [DeletionCompletion] = []
    private(set) var receivedMessages = [ReceivedMessage]()
    
    func deleteChachedFeeds(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCacheFeed)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date) {
        receivedMessages.append(.insert(items: items, timestamp: timestamp))
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        // Given
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        // When
        sut.save(items)
        // Then
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        // Given
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let deletionError = anyError
        // When
        sut.save(items)
        store.completeDeletion(with: deletionError)
        // Then
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccesfulDeletion() {
        // Given
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = [uniqueItem(), uniqueItem()]
        // When
        sut.save(items)
        store.completeDeletionSuccessfully()
        // Then
        XCTAssertEqual(
            store.receivedMessages, [
                .deleteCacheFeed,
                .insert(items: items, timestamp: timestamp)
            ]
        )
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private var anyError: NSError {
        NSError(
            domain: "any error",
            code: 0
        )
    }
    
    private func uniqueItem() -> FeedItem {
        FeedItem(
            id: UUID(),
            description: "any description",
            location: "any location",
            imageURL: URL(string: "https://any-url.com")!
        )
    }
    
}
