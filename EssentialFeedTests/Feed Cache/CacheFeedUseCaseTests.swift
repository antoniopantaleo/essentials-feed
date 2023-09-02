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
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        XCTAssertEqual(store.deleteCacheFeedCallCount, 0)
    }
    
    func test_save_requestsCacheDeletion() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        let items = [uniqueItem(), uniqueItem()]
        sut.save(items)
        
        XCTAssertEqual(store.deleteCacheFeedCallCount, 1)
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
