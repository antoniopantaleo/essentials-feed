//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Antonio Pantaleo on 25/08/23.
//

import Foundation

public final class FeedItemsMapper {
    private static let decoder = JSONDecoder()
    private static let OK_200 = 200
    
    private struct Root: Decodable {
        private let items: [RemoteFeedItem]
        
        struct RemoteFeedItem: Decodable {
            let id: UUID
            let description: String?
            let location: String?
            let image: URL
        }
        
        var images: [FeedImage] {
            items.map {
                FeedImage(
                    id: $0.id,
                    description: $0.description,
                    location: $0.location,
                    url: $0.image
                )
            }
        }
    }
    
    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> [FeedImage] {
        guard
            response.statusCode == OK_200,
            let root = try? decoder.decode(Root.self, from: data)
        else { throw RemoteFeedLoader.Error.invalidData }
        return root.images
    }
}
