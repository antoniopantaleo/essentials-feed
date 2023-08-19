//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Antonio on 19/08/23.
//

import Foundation

/// Public because it can be implemented by external modules
public protocol HTTPClient {
    func get(from url: URL)
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load() {
        client.get(from: url)
    }
}
