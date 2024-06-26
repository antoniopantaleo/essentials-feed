//
//  LocalFeedImageLoader.swift
//  EssentialFeed
//
//  Created by Antonio Pantaleo on 16/03/24.
//

import Foundation

public protocol FeedImageDataStore {
    typealias RetrievalResult = Swift.Result<Data?, Error>
    typealias InsertionResult = Swift.Result<Void, Error>

    func insert(_ data: Data, for url: URL, completion: @escaping (InsertionResult) -> Void)
    func retrieve(dataForURL url: URL, completion: @escaping (RetrievalResult) -> Void)
}

public class LocalFeedImageLoader: FeedImageLoader {
    
    private let store: FeedImageDataStore
    
    public init(store: FeedImageDataStore) {
        self.store = store
    }
    
    public func loadImageData(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        let task = Task(completion)
        store.retrieve(dataForURL: url) { [weak self] result in
            guard self != nil else { return }
            task.complete(with:
                result
                .mapError { _ in Error.failed }
                .flatMap { data in
                    data.map { .success($0) } ?? .failure(Error.notFound)
                }
            )
        }
        return task
    }
}

extension LocalFeedImageLoader: FeedImageCache {
    public typealias SaveResult = FeedImageCache.Result
    
    public func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
        store.insert(data, for: url) { [weak self] result in
            guard self != nil else { return }
            completion(result.mapError { _ in SaveError.failed })
        }
    }
}

extension LocalFeedImageLoader {
    
    public enum Error: Swift.Error {
        case failed
        case notFound
    }

    public enum SaveError: Swift.Error {
        case failed
    }
    
    private final class Task: FeedImageDataLoaderTask {
        private var completion: ((FeedImageLoader.Result) -> Void)?
        
        init(_ completion: @escaping (FeedImageLoader.Result) -> Void) {
            self.completion = completion
        }
        
        func complete(with result: FeedImageLoader.Result) {
            completion?(result)
        }
        
        private func preventFurtherCompletions() {
            completion = nil
        }
        
        func cancel() {
            preventFurtherCompletions()
        }
    }
    
}
