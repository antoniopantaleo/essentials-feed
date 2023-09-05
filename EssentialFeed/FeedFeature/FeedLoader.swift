//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Antonio on 19/08/23.
//

import Foundation

public enum LoadFeedResult{
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
