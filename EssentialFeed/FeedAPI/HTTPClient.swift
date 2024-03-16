//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Antonio Pantaleo on 25/08/23.
//

import Foundation

public typealias HTTPClientResult = Result<(Data, HTTPURLResponse), Error>

public protocol HTTPClientTask {
    func cancel()
}

/// Public because it can be implemented by external modules
public protocol HTTPClient {
    @discardableResult
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) -> HTTPClientTask
}
