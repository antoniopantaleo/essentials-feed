//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Antonio on 05/09/23.
//

import Foundation

/// This is a FeedItem DTO representation only used by the API module
struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
