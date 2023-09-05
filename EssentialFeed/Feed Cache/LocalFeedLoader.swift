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
    
    public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteChachedFeeds { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(items, with: completion)
            }
        }
    }
    
    private func cache(_ items: [FeedItem], with completion: @escaping (SaveResult) -> Void) {
        store.insert(
            items.toLocalFeedIdem,
            timestamp: self.currentDate(),
            completion: { [weak self] error in
                guard self != nil else { return }
                completion(error)
            }
        )
    }
}

fileprivate extension Array where Element == FeedItem {
    var toLocalFeedIdem: [LocalFeedItem] {
        map {
            LocalFeedItem(
                id: $0.id,
                description: $0.description,
                location: $0.location,
                imageURL: $0.imageURL
            )
        }
    }
}
