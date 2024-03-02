//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Antonio on 30/09/23.
//

import Foundation

public class CodableFeedStore: FeedStore {
    
    private struct Cache: Codable {
        let feed: [CodableLocalFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map { $0.localFeedImage }
        }
    }
    
    private struct CodableLocalFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var localFeedImage: LocalFeedImage {
            LocalFeedImage(
                id: id,
                description: description,
                location: location,
                url: url
            )
        }
    }
    
    private let storeURL: URL
    
    /// This is by default a backgronud thread, but operations run serially, insted of DispatchQueue.global().async, which runs concurrently.
    private let backgroundSerialQueue = DispatchQueue(
        label: "\(CodableFeedStore.self)Queue",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        // This allows us to capture self.storeURL without capturing self, which would create a retain cycle.
        let storeURL = self.storeURL
        backgroundSerialQueue.async(flags: .barrier) {
            do {
                let encoder = JSONEncoder()
                let cache = Cache(feed: feed.map(CodableLocalFeedImage.init), timestamp: timestamp)
                let encoded = try encoder.encode(cache)
                try encoded.write(to:  storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        // This allows us to capture self.storeURL without capturing self, which would create a retain cycle.
        let storeURL = self.storeURL
        backgroundSerialQueue.async {
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.empty)
            }
            let decoder = JSONDecoder()
            do {
                let cache = try decoder.decode(Cache.self, from: data)
                completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        // This allows us to capture self.storeURL without capturing self, which would create a retain cycle.
        let storeURL = self.storeURL
        backgroundSerialQueue.async(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: storeURL.path) else {
                return completion(nil)
            }
            do {
                try FileManager.default.removeItem(at: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
}
