//
//  RemoteFeedImageLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 15/03/24.
//

import XCTest
import EssentialFeed

class RemoteFeedImageLoader: FeedImageLoader {
    
    private let client: HTTPClient
    
    struct Task: FeedImageDataLoaderTask {
        func cancel() {}
    }
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        Task()
    }
    
    
}

final class RemoteFeedImageLoaderTests: XCTestCase {
    
    func test_init_doesNotPerformAnyURLRequest() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    private func makeSUT(
        url: URL = anyURL,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: RemoteFeedImageLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedImageLoader(client: client)
        trackMemoryLeaks(sut, file: file, line: line)
        trackMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        
        func get(
            from url: URL,
            completion: @escaping (EssentialFeed.HTTPClientResult
        ) -> Void) {
            requestedURLs.append(url)
        }
    }
}
