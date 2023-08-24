//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Antonio on 19/08/23.
//

import Foundation

public enum HTTPClientResult {
    case success(HTTPURLResponse)
    case failure(Error)
}

/// Public because it can be implemented by external modules
public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Error) -> Void) {
        client.get(from: url) { result in
            if case .success(_) = result {
                completion(.invalidData)
            } else {
                completion(.connectivity)
            }
        }
    }
}
