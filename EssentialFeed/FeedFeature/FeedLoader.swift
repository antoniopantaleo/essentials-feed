//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Antonio on 19/08/23.
//

import Foundation

/// We need to make this enum equatable since we use arrays in test
/// But Error is a protocol and it could be not equatable
/// We use a generic constranits
/// ensuring that the tests will use the equatable version using the extension below
public enum LoadFeedResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

/// It means: if the error is equatable, then the enum is equatable
extension LoadFeedResult: Equatable where Error: Equatable { }

/// We need to handle the generic constraint here too
/// It has to be generic, so we use an assciated type
protocol FeedLoader {
    associatedtype Error: Swift.Error
    func load(completion: @escaping (LoadFeedResult<Error>) -> Void)
}
