//
//  FeedCache.swift
//  EssentialFeed
//
//  Created by Antonio on 25/03/24.
//

import Foundation

public protocol FeedCache {
    typealias Result = Swift.Result<Void, Error>
    
    func save(_ feed: [FeedImage], completion: @escaping (Result) -> Void)
}
