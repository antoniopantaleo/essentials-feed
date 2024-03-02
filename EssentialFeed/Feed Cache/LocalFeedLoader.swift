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
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
}

extension LocalFeedLoader {
    public typealias SaveResult = Error?

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
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

extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = LoadFeedResult
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
                case let .failure(error):
                    completion(.failure(error))
            case let .found(feed, timestamp) where FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                    completion(.success(feed.toFeedImage))
                case .found, .empty:
                    completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoader {
    
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
                case .failure:
                    self.store.deleteCachedFeed { _ in }
                case let .found(_, timestamp) where !FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                    self.store.deleteCachedFeed { _ in }
                case .found, .empty:
                    break
            }
        }
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
