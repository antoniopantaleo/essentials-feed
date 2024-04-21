//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 25/08/23.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL
        let expectation = expectation(description: "Waiting for request")
        
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
        }
        let sut = makeSUT()
        sut.get(from: url) { _ in }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let requestError = anyNSError
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError) as? NSError
        XCTAssertEqual(receivedError?.domain, requestError.domain)
        XCTAssertEqual(receivedError?.code, requestError.code)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: nil))
    }
    
    func test_getFromURL_succeedsOnHTTPResponseWithEmptyData() {
        let expectedResponse = anyHTTPURLResponse
        let receivedValues = resultValuesFor(data: nil, response: expectedResponse, error: nil)
        
        XCTAssertEqual(receivedValues.data?.count, 0)
        XCTAssertEqual(receivedValues.response?.url, expectedResponse.url)
        XCTAssertEqual(receivedValues.response?.statusCode, expectedResponse.statusCode)
    }
    
    func test_getFromURL_succeedsOnHTTPResponseWithData() {
        let expectedData = anyData
        let expectedResponse = anyHTTPURLResponse
        let receivedValues = resultValuesFor(data: expectedData, response: expectedResponse, error: nil)
        
        XCTAssertEqual(receivedValues.data, expectedData)
        XCTAssertEqual(receivedValues.response?.url, expectedResponse.url)
        XCTAssertEqual(receivedValues.response?.statusCode, expectedResponse.statusCode)
    }
    
    // MARK: Helpers
    
    private var nonHTTPURLResponse: URLResponse {
        URLResponse(
            url: anyURL,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
    }
    
    private var anyHTTPURLResponse: HTTPURLResponse {
        HTTPURLResponse(
            url: anyURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
    }
    
    private var anyData: Data {
        Data("any data".utf8)
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let client = URLSessionHTTPClient(session: session)
        trackMemoryLeaks(client, file: file, line: line)
        return client
    }
    
    private func resultErrorFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        guard case .failure(let error) = result else {
            XCTFail("Expected failure got \(result) instead")
            return nil
        }
        return error
    }
    
    private func resultValuesFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (data: Data?, response: HTTPURLResponse?) {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        guard case .success((let data, let response)) = result else {
            XCTFail("Expected success got \(result) instead")
            return (nil, nil)
        }
        return (data, response)
    }
    
    private func resultFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        var receivedResult: HTTPClientResult!
        
        let expectation = expectation(description: "Wait for completion")
        sut.get(from: anyURL) { result in
            switch result {
            case .success((let data, let response)):
                receivedResult = .success((data, response))
            case .failure(let error):
                receivedResult = .failure(error)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        return receivedResult
    }
    
}
