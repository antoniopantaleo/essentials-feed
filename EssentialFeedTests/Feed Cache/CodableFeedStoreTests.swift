//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 24/09/23.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.empty)
    }
    
}

final class CodableFeedStoreTests: XCTestCase {

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "Wait for completion")
        sut.retrieve { result in
            guard case .empty = result else {
                return XCTFail("Expected empty result, got \(result) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

}
