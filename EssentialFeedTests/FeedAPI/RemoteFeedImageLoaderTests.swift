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
        client.get(from: url) { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case .success:
                break
            }
        }
        return Task()
    }
    
    
}

final class RemoteFeedImageLoaderTests: XCTestCase {
    
    func test_init_doesNotPerformAnyURLRequest() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_loadImageDataFromURL_requestsDataFromURL() {
        let (sut, client) = makeSUT(url: anyURL)
        
        _ = sut.loadImageData(from: anyURL) { _ in }
        XCTAssertEqual(client.requestedURLs, [anyURL])
    }
    
    func test_loadImageDataFromURLTwice_requestsDataFromURLTwice() {
        let (sut, client) = makeSUT(url: anyURL)
        
        _ = sut.loadImageData(from: anyURL) { _ in }
        _ = sut.loadImageData(from: anyURL) { _ in }
        
        XCTAssertEqual(client.requestedURLs, [anyURL, anyURL])
    }
    
    func test_loadImageDataFromURL_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let clientError = NSError(domain: "a client error", code: 0)
        
        expect(sut, toCompleteWith: .failure(clientError), when: {
            client.complete(with: clientError)
        })
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
    
    private func expect(
        _ sut: RemoteFeedImageLoader,
        toCompleteWith expectedResult: FeedImageLoader.Result,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let url = anyURL
        let exp = expectation(description: "Wait for load completion")
        
        _ = sut.loadImageData(from: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }

    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(
            from url: URL,
            completion: @escaping (EssentialFeed.HTTPClientResult
            ) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
    }
}
