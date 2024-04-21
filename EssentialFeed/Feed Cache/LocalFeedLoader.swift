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

extension LocalFeedLoader: FeedCache {
    public typealias SaveResult = Swift.Result<Void,Error>

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(.failure(cacheDeletionError))
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
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        )
    }
}

extension LocalFeedLoader {
    public typealias LoadResult = Swift.Result<[FeedImage], Error>
    
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
    public typealias ValidationResult = Result<Void, Error>
    
    public func validateCache(completion: @escaping (ValidationResult) -> Void = { _ in }) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
                case .failure:
                    self.store.deleteCachedFeed { error in
                        if let error { completion(.failure(error)) } else {
                            completion(.success(()))
                        }
                    }
                case let .found(_, timestamp) where !FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                    self.store.deleteCachedFeed { error in
                        if let error { completion(.failure(error)) } else {
                            completion(.success(()))
                        }
                    }
                case .found, .empty:
                    completion(.success(()))
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
