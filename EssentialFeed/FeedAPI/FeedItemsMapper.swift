//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Antonio Pantaleo on 25/08/23.
//

import Foundation

final class FeedItemsMapper {
    private static let decoder = JSONDecoder()
    private static let OK_200 = 200
    
    private struct Root: Decodable {
        private let items: [Item]
        var feeds: [FeedItem] { items.map { $0.asFeedItem } }
    }

    /// This is a FeedItem representation only used by the API module
    private struct Item: Decodable {
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
    
    /// A way to avoid to weak-ify self and avoid reatin cycles is to use static func
    static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard
            response.statusCode == OK_200,
            let root = try? decoder.decode(Root.self, from: data)
        else { return .failure(.invalidData) }
        
        let items = root.feeds
        return .success(items)
    }
}
