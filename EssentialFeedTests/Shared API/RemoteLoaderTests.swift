//
//  RemoteLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 15/03/24.
//

import XCTest
import EssentialFeed

final class RemoteLoaderTests: XCTestCase {
    
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
        
        expect(sut, toCompleteWith: .failure(RemoteFeedImageLoader.Error.connectivity), when: {
            client.complete(with: clientError)
        })
    }
    
    func test_loadImageDataFromURL_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                client.complete(withStatusCode: code, data: Data("any-data".utf8), at: index)
            })
        }
    }
    
    func test_loadImageDataFromURL_deliversInvalidDataErrorOn200HTTPResponseWithEmptyData() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let emptyData = Data()
            client.complete(withStatusCode: 200, data: emptyData)
        })
    }
    
    func test_loadImageDataFromURL_deliversReceivedNonEmptyDataOn200HTTPResponse() {
        let (sut, client) = makeSUT()
        let nonEmptyData = Data("non-empty data".utf8)
        
        expect(sut, toCompleteWith: .success(nonEmptyData), when: {
            client.complete(withStatusCode: 200, data: nonEmptyData)
        })
    }
    
    func test_loadImageDataFromURL_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let client = HTTPClientSpy()
        var sut: RemoteFeedImageLoader? = RemoteFeedImageLoader(client: client)
        
        var capturedResults = [FeedImageLoader.Result]()
        _ = sut?.loadImageData(from: anyURL) { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: Data("any-data".utf8))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    //MARK: - Helpers
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
    
    private func failure(_ error: RemoteFeedImageLoader.Error) -> FeedImageLoader.Result {
        return .failure(error)
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
            case let (.failure(receivedError as RemoteFeedImageLoader.Error), .failure(expectedError as RemoteFeedImageLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
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
    
    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let (sut, client) = makeSUT()
        let exp = expectation(description: "Wait for request")
        exp.isInverted = true
        
        let task = sut.loadImageData(from: anyURL) { result in
            switch result {
            case let .failure(error as NSError) where error.code == URLError.cancelled.rawValue:
                break
            default:
                XCTFail("Expected cancelled result, got \(result) instead")
            }
            exp.fulfill()
        }
        task.cancel()
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(client.cancelledURLs, [anyURL])
    }
    
    private class HTTPClientSpy: HTTPClient {
        private struct Task: HTTPClientTask {
            var onCancel: (() -> Void)?
            
            func cancel() {
                onCancel?()
            }
        }
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        private(set) var cancelledURLs = [URL]()
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        @discardableResult
        func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) -> HTTPClientTask {
            let task = Task { [weak self] in
                self?.cancelledURLs.append(url)
            }
            messages.append((url, completion))
            return task
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success((data, response)))
        }
    }
}
