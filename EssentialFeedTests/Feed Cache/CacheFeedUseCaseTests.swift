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
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteChachedFeeds { [unowned store] error in
            if error == nil {
                store.insert()
            }
        }
    }
}

/// This class help us to abstract the framework we are going to use from the tests
class FeedStore {
    typealias DeletionCompletion = ((Error?) -> Void)
    private(set) var deleteCacheFeedCallCount: Int = 0
    private(set) var insertCallCount = 0
    
    private var deletionCompletions: [DeletionCompletion] = []
    
    func deleteChachedFeeds(completion: @escaping DeletionCompletion) {
        deleteCacheFeedCallCount += 1
        deletionCompletions.append(completion)
    }
    
    func insert() {
        insertCallCount += 1
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotClearCacheUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.deleteCacheFeedCallCount, 0)
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        sut.save(items)
        
        XCTAssertEqual(store.deleteCacheFeedCallCount, 1)
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
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    func test_save_requestNewCacheInsertionOnSuccesfulDeletion() {
        // Given
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        // When
        sut.save(items)
        store.completeDeletionSuccessfully()
        // Then
        XCTAssertEqual(store.insertCallCount, 1)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
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
