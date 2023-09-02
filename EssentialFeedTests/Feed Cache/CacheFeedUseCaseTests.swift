//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 02/09/23.
//

import XCTest


class LocalFeedLoader {
    private var store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
}

/// This class help us to abstract the framework we are going to use from the tests
class FeedStore {
    private(set) var deleteCacheFeedCallCount: Int = 0
    
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotClearCacheUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        XCTAssertEqual(store.deleteCacheFeedCallCount, 0)
    }
    
}
