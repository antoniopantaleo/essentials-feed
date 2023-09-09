//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Antonio on 05/09/23.
//

import Foundation

public final class LocalFeedLoader {
    private var store: FeedStore
    private var currentDate: () -> Date
    
    public typealias SaveResult = Error?
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func load(completion: @escaping (Error?) -> Void) {
        store.retrieve(completion: completion)
    }
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteChachedFeeds { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(feed, with: completion)
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(
            feed.toLocalFeedIdem,
            timestamp: self.currentDate(),
            completion: { [weak self] error in
                guard self != nil else { return }
                completion(error)
            }
        )
    }
}

fileprivate extension Array where Element == FeedImage {
    var toLocalFeedIdem: [LocalFeedImage] {
        map {
            LocalFeedImage(
                id: $0.id,
                description: $0.description,
                location: $0.location,
                url: $0.url
            )
        }
    }
}
