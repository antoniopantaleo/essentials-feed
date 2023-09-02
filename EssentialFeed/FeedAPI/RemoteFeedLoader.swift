//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Antonio on 19/08/23.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    /// We are specyfing the error type here
    public typealias Result = LoadFeedResult
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            /// We use this guard here to prevent OS to execute the static method
            /// if the RemoteFeedLoader instance has been deleted
            guard self != nil else { return }
            switch result {
            case let .success(data, response):
                let result = FeedItemsMapper.map(data, from: response)
                completion(result)
            case .failure(_):
                completion(.failure(Error.connectivity))
            }
        }
    }
    
}
