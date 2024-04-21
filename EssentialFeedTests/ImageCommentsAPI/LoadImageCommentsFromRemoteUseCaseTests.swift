//
//  LoadImageCommentsFromRemoteUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Antonio on 19/08/23.
//

import XCTest
import EssentialFeed

final class LoadImageCommentsFromRemoteUseCaseTests: XCTestCase {
    

    func test_load_deliversErrorOnNon2xxHTTPResponse() {
        let (sut, client) = makeSUT()
        let statusCodes = [199, 140, 300, 400, 500]
        
        statusCodes
            .enumerated()
            .forEach { index, code in
                expect(
                    sut,
                    toCompleteWithResult: failure(.invalidData),
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
    
    func test_load_deliversErrorOn2xxHTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        let samples = [200, 201, 250, 280, 299]
        samples.enumerated().forEach { index, code in
            expect(
                sut,
                toCompleteWithResult: failure(.invalidData),
                when: {
                    let invalidJson = Data("invalid data".utf8)
                    client.complete(withStatusCode: code, data: invalidJson, at: index)
                }
            )
        }
    }
    
    func test_load_deliversNoItemsOn2xxHTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        let samples = [200, 201, 250, 280, 299]
        
        samples.enumerated().forEach { index, code in
            expect(
                sut,
                toCompleteWithResult: .success([]),
                when: {
                    let emptyListJSON = makeItemsJSON([])
                    client.complete(withStatusCode: code, data: emptyListJSON, at: index)
                }
            )
        }
    }
    
    // Happy Path
    func test_load_deliversItemsOn2xxHTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(
            id: UUID(),
            message: "a message",
            createdAt: (Date(timeIntervalSince1970: 1598627222), "2020-08-28T15:07:02+00:00"),
            username: "a username"
        )
        
        let item2 = makeItem(
            id: UUID(),
            message: "another message",
            createdAt: (Date(timeIntervalSince1970: 1577881882), "2020-01-01T12:31:22+00:00"),
            username: "another username"
        )
        let models = [item1.model, item2.model]
        
        let samples = [200, 201, 250, 280, 299]
        
        samples.enumerated().forEach { index, code in
            expect(
                sut,
                toCompleteWithResult: .success(models),
                when: {
                    let json = makeItemsJSON([item1.json, item2.json])
                    client.complete(withStatusCode: code, data: json, at: index)
                }
            )
        }
    }
    
    //MARK: Helpers
    
    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteImageCommentsLoader, client: HTTPClientSpy) {
        /// We need to check memory leaks both for the client and the SUT
        let client = HTTPClientSpy()
        let sut = RemoteImageCommentsLoader(url: url, client: client)
        trackMemoryLeaks(sut, file: file, line: line)
        trackMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }
    
    // Factory Method
    private func makeItem(
        id: UUID,
        message: String,
        createdAt: (date: Date, iso8601String: String),
        username: String
    ) -> (
        model: ImageComment,
        json: [String: Any]
    ) {
        let model = ImageComment(
            id: id,
            message: message,
            createdAt: createdAt.date,
            username: username
        )
        
        /// We use compact map to remove optional values
        /// Otherwise the types don't matches
        /// [String:Any?] != [String:Any]
        let json: [String: Any] = [
            "id": model.id.uuidString,
            "message": message,
            "created_at": createdAt.iso8601String,
            "author": [
                "username": username
            ]
        ].compactMapValues { $0 }
        
        return (model, json)
    }
    
    private func failure(_ error: RemoteImageCommentsLoader.Error) -> RemoteImageCommentsLoader.Result {
        .failure(error)
    }
    
    private func makeItemsJSON(_ items: [[String:Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(
        _ sut: RemoteImageCommentsLoader,
        toCompleteWithResult expectedResult: RemoteImageCommentsLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        /// We need to replace the array approach that checks the singolarity of operations
        /// We use XCTest expectations for that
        let expectation = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedItems), .success(let expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case (
                .failure(let receivedError as RemoteImageCommentsLoader.Error),
                .failure(let expectedError as RemoteImageCommentsLoader.Error)
            ):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail(
                    "Expected \(expectedResult) but got \(receivedResult) insted",
                    file: file,
                    line: line
                )
            }
            expectation.fulfill()
        }
        
        action()
        wait(for: [expectation], timeout: 1.0)
    }
}
