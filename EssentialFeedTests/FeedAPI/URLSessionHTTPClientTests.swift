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
        let expectation1 = expectation(description: "Waiting for request")
        let expectation2 = expectation(description: "Waiting for completion")
        
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation1.fulfill()
        }
        let sut = makeSUT()
        sut.get(from: url) { _ in
            expectation2.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let requestError = anyError as NSError
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError) as? NSError
        XCTAssertEqual(receivedError?.domain, requestError.domain)
        XCTAssertEqual(receivedError?.code, requestError.code)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: anyError))
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
    
    private var anyURL: URL {
        URL(string: "https://any-url.com")!
    }
    
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
    
    private var anyError: Error {
        NSError(domain: "any error", code: 0)
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let client = URLSessionHTTPClient()
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
        guard case .success(let data, let response) = result else {
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
            case .success(let data, let response):
                receivedResult = .success(data, response)
            case .failure(let error):
                receivedResult = .failure(error)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        return receivedResult
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        /// This struct maps the closure we get from our HTTPClient.get method
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        static func observeRequest(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        /// We intercept all requests
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() { }
  
    }
    
}
