//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 25/08/23.
//

import XCTest
import EssentialFeed

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

class URLSessionHTTPClient {
    private let session: HTTPSession
    
    init(session: HTTPSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_resumeDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let session = HTTPSessionSpy()
        let task = URLSessionDataTaskSpy()
        /// We need a way to link our session to a data task
        session.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "http://any-url.com")!
        let session = HTTPSessionSpy()
        let error = NSError(domain: "any error", code: 0)
        /// We need a way to link our session to a data task
        session.stub(url: url, error: error)
        let sut = URLSessionHTTPClient(session: session)
        let expecation = expectation(description: "Wait for completion")
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail("Excpected failure with error \(error) but got \(result)")
            }
            expecation.fulfill()
        }
        wait(for: [expecation], timeout: 1.0)
    }
    
    // MARK: Helpers
    
    private class FakeURLSessionDataTask: HTTPSessionTask {
        /// Mandatory to prevent crash when testing due to an unimplemented function
        func resume() {
        }
    }
    private class URLSessionDataTaskSpy: HTTPSessionTask {
        private(set) var resumeCallCount = 0
        
        func resume() {
            resumeCallCount += 1
        }
    }
    
    private class HTTPSessionSpy: HTTPSession {
        private var stubs = [URL: Stub]()
        private struct Stub {
            let task: HTTPSessionTask
            let error: Error?
        }
        func stub(
            url: URL,
            task: HTTPSessionTask = FakeURLSessionDataTask(),
            error: Error? = nil
        ) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
            guard let stub = stubs[url] else {
                fatalError("Couldn't find stub for \(url.absoluteString)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }
    
}
