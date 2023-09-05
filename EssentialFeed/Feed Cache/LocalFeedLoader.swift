//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Antonio on 05/09/23.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = ((Error?) -> Void)
    typealias InsertionCompletion = ((Error?) -> Void)
    
    func deleteChachedFeeds(completion: @escaping DeletionCompletion)
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}


public final class LocalFeedLoader {
    private var store: FeedStore
    private var currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteChachedFeeds { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(items, with: completion)
            }
        }
    }
    
    private func cache(_ items: [FeedItem], with completion: @escaping (Error?) -> Void) {
        store.insert(
            items,
            timestamp: self.currentDate(),
            completion: { [weak self] error in
                guard self != nil else { return }
                completion(error)
            }
        )
    }
}
