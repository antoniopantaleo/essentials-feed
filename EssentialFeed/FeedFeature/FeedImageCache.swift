//
//  FeedImageCache.swift
//  EssentialFeed
//
//  Created by Antonio on 25/03/24.
//

import Foundation

public protocol FeedImageCache {
    typealias Result = Swift.Result<Void, Error>
    
    func save(_ data: Data, for url: URL, completion: @escaping (Result) -> Void)
}
