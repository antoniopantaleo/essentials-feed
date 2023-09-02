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
        store.deleteChachedFeeds()
    }
}

/// This class help us to abstract the framework we are going to use from the tests
class FeedStore {
    private(set) var deleteCacheFeedCallCount: Int = 0
    
    func deleteChachedFeeds() {
        deleteCacheFeedCallCount += 1
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
    
    // MARK: Helpers
    
    private func makeSUT() -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        return (sut, store)
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
