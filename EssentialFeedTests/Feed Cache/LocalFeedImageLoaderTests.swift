//
//  LocalFeedImageLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 16/03/24.
//

import XCTest
import EssentialFeed

class LocalFeedImageLoader: FeedImageLoader {
    
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    struct Task: FeedImageDataLoaderTask {
        func cancel() {}
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        return Task()
    }
    
    
}

final class LocalFeedImageLoaderTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()        
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }

 
    // MARK: - Helpers
    
    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: LocalFeedImageLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedImageLoader(store: store)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private class FeedStoreSpy: FeedStore {
        
        let receivedMessages = [Any]()
        
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {}
        
        func insert(_ feed: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {}
        
        func retrieve(completion: @escaping RetrievalCompletion) {}
    }
    
}
