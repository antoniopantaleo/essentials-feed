//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Antonio on 19/08/23.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
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
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            if case .success(let data, let response) = result {
                do {
                    let items = try FeedItemsMapper.map(data, response)
                    completion(.success(items))
                } catch {
                    completion(.failure(.invalidData))
                }
            } else {
                completion(.failure(.connectivity))
            }
        }
    }
}

fileprivate class FeedItemsMapper {
    private static let decoder = JSONDecoder()
    
    struct Root: Decodable {
        let items: [Item]
    }

    /// This is a FeedItem representation only used by the API module
    struct Item: Decodable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let image: URL

        var asFeedItem: FeedItem {
            FeedItem(
                id: id,
                description: description,
                location: location,
                imageURL: image
            )
        }
    }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == 200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        return try decoder
            .decode(Root.self, from: data)
            .items
            .map { $0.asFeedItem }
    }
}
