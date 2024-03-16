//
//  RemoteFeedImageLoader.swift
//  EssentialFeed
//
//  Created by Antonio Pantaleo on 16/03/24.
//

import Foundation

public class RemoteFeedImageLoader: FeedImageLoader {
    
    private let client: HTTPClient
    
    public init(client: HTTPClient) {
        self.client = client
    }
    
    @discardableResult
    public func loadImageData(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        let task = client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .failure:
                completion(.failure(Error.connectivity))
            case let .success((data, response)):
                if response.statusCode == 200, !data.isEmpty {
                    completion(.success(data))
                } else {
                    completion(.failure(Error.invalidData))
                }
            }
        }
        return HTTPTaskWrapper(wrapped: task)
    }
}

extension RemoteFeedImageLoader {
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    private struct HTTPTaskWrapper: FeedImageDataLoaderTask {
        let wrapped: HTTPClientTask
        
        func cancel() {
            wrapped.cancel()
        }
    }
    
}
