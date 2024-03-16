//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Antonio Pantaleo on 26/08/23.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession) {
        self.session = session
    }
    
    /// This should never happen (e.g. data, response and error are all nil)
    private struct UnexpectedValuesRepresentation: Error {}
    
    @discardableResult
    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) -> HTTPClientTask {
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }
        task.resume()
        return URLSessionTaskWrapper(wrapped: task)
    }
}

extension URLSessionHTTPClient {
    private struct URLSessionTaskWrapper: HTTPClientTask {
        let wrapped: URLSessionTask
        
        func cancel() {
            wrapped.cancel()
        }
    }
}
