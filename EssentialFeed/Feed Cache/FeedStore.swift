//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Antonio on 05/09/23.
//

import Foundation

public enum RetrieveCahedFeedResult {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
    case failure(Error)
}

public protocol FeedStore {
    typealias DeletionCompletion = ((Error?) -> Void)
    typealias InsertionCompletion = ((Error?) -> Void)
    typealias RetrievalCompletion = ((RetrieveCahedFeedResult) -> Void)
    
    func deleteChachedFeeds(completion: @escaping DeletionCompletion)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrievalCompletion)
}