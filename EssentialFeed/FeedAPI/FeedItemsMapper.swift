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
        let items: [RemoteFeedItem]
    }
    
    /// A way to avoid to weak-ify self and avoid reatin cycles is to use static func
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard
            response.statusCode == OK_200,
            let root = try? decoder.decode(Root.self, from: data)
        else { throw RemoteFeedLoader.Error.invalidData }
        return root.items
    }
}
