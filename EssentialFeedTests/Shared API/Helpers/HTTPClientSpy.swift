//
//  HTTPClientSpy.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 21/04/24.
//

import Foundation
import EssentialFeed

class HTTPClientSpy: HTTPClient {
    
    private struct Task: HTTPClientTask {
        func cancel() { }
    }
    
    typealias Message = (url: URL, completion: (HTTPClientResult) -> Void)
    private var messages = [Message]()
    
    var requestedURLs: [URL] {
        messages.map { $0.url }
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) -> HTTPClientTask {
        messages.append((url, completion))
        return Task()
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
        messages[index].completion(.success((data, response)))
    }
}
