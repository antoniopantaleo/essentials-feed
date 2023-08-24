//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Antonio on 19/08/23.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        /// We are asserting that we didn't make a URL request since that
        /// should only happen when `.load()` is invoked
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    /// connectivity issue
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(
            sut,
            toCompleteWithResult: .failure(.connectivity),
            when: {
                let clientError = NSError(domain: "Test", code: 0)
                client.complete(with: clientError)
            }
        )
    }
    
    // wrong HTTP status code
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let statusCodes = [199, 201, 300, 400, 500]
        
        statusCodes
            .enumerated()
            .forEach { index, code in
                expect(
                    sut,
                    toCompleteWithResult: .failure(.invalidData),
                    when: {
                        let json = makeItemsJSON([])
                        client.complete(
                            withStatusCode: code,
                            data: json,
                            at: index
                        )
                    }
                )
        }
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(
            sut,
            toCompleteWithResult: .failure(.invalidData),
            when: {
                let invalidJson = Data("invalid data".utf8)
                client.complete(withStatusCode: 200, data: invalidJson)
            }
        )
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(
            sut,
            toCompleteWithResult: .success([]),
            when: {
                let emptyJsonList = makeItemsJSON([])
                client.complete(withStatusCode: 200, data: emptyJsonList)
            }
        )
    }
    
    // Happy Path
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "https://a-url.com")!
        )
        
        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "https://another-url.com")!
        )
        
        let models = [item1.model, item2.model]
        expect(
            sut,
            toCompleteWithResult: .success(models),
            when: {
                let json = makeItemsJSON([item1.json, item2.json])
                client.complete(withStatusCode: 200, data: json)
            }
        )
    }
    
    //MARK: Helpers
    
    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!
    ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    // Factory Method
    private func makeItem(
        id: UUID,
        description: String? = nil,
        location: String? = nil,
        imageURL: URL
    ) -> (model: FeedItem, json: [String: Any]) {
        let model = FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: imageURL
        )
        
        /// We use compact map to remove optional values
        /// Otherwise the types don't matches
        /// [String:Any?] != [String:Any]
        let json = [
            "id": model.id.uuidString,
            "description": model.description,
            "location": model.location,
            "image": model.imageURL.absoluteString
        ].compactMapValues { $0 }
        
        return (model, json)
    }
    
    private func makeItemsJSON(_ items: [[String:Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWithResult result: RemoteFeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(
            capturedResults,
            [result],
            file: file,
            line: line
        )
    }
    
    private class HTTPClientSpy: HTTPClient {
        typealias Message = (url: URL, completion: (HTTPClientResult) -> Void)
        private var messages = [Message]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(
            withStatusCode code: Int,
            data: Data,
            at index: Int = 0
        ) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(data, response))
        }
    }
}
