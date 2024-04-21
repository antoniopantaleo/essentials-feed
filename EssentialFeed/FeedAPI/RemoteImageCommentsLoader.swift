//
//  RemoteImageCommentsLoader.swift
//  EssentialFeed
//
//  Created by Antonio Pantaleo on 16/03/24.
//

import Foundation

public final class RemoteImageCommentsLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = Swift.Result<[ImageComment], Swift.Error>
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            /// We use this guard here to prevent OS to execute the static method
            /// if the RemoteImageCommentsLoader instance has been deleted
            guard self != nil else { return }
            switch result {
            case let .success((data, response)):
                let result = RemoteImageCommentsLoader.map(data, from: response)
                completion(result)
            case .failure(_):
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            let items = try ImageCommentsMapper.map(data, from: response)
            return .success(items)
        } catch {
            return .failure(error)
        }
    }
}
