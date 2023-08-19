//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Antonio on 19/08/23.
//

import XCTest

class RemoteFeedLoader {
    
}

class HTTPClient {
    var requestedURL: URL?
}

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient()
        let sut = RemoteFeedLoader()
        /// We are asserting that we didn't make a URL request since that
        /// should only happen when `.load()` is invoked
        XCTAssertNil(client.requestedURL)
    }
    
}
