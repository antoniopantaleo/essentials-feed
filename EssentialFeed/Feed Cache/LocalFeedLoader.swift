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
    public typealias LoadResult = LoadFeedResult
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [unowned self] result in
            switch result {
                case let .failure(error):
                    completion(.failure(error))
                case let .found(feed, timestamp) where self.validate(timestamp):
                    completion(.success(feed.toFeedImage))
                case .found, .empty:
                    completion(.success([]))
            }
        }
    }
    
    
    private func validate(_ timestamp: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        guard let maxCacheAge = calendar.date(byAdding: .day, value: 7, to: timestamp) else { return false }
        return currentDate() < maxCacheAge
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
            feed.toLocalFeedItem,
            timestamp: self.currentDate(),
            completion: { [weak self] error in
                guard self != nil else { return }
                completion(error)
            }
        )
    }
}

fileprivate extension Array where Element == FeedImage {
    var toLocalFeedItem: [LocalFeedImage] {
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

fileprivate extension Array where Element == LocalFeedImage {
    var toFeedImage: [FeedImage] {
        map {
            FeedImage(
                id: $0.id,
                description: $0.description,
                location: $0.location,
                url: $0.url
            )
        }
    }
}
