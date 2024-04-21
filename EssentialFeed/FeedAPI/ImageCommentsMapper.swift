//
//  ImageCommentsMapper.swift
//  EssentialFeed
//
//  Created by Antonio Pantaleo on 25/08/23.
//

import Foundation

final class ImageCommentsMapper {
    private static let decoder = JSONDecoder()
    
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    /// A way to avoid to weak-ify self and avoid reatin cycles is to use static func
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard
            isOK(response),
            let root = try? decoder.decode(Root.self, from: data)
        else { throw RemoteImageCommentsLoader.Error.invalidData }
        return root.items
    }
    
    private static func isOK(_ response: HTTPURLResponse) -> Bool {
        (200...299).contains(response.statusCode)
    }
}
