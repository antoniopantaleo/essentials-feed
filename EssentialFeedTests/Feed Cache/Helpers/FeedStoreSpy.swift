//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Antonio on 09/09/23.
//

import Foundation
import EssentialFeed

/// This class help us to abstract the framework we are going to use from the tests
class FeedStoreSpy: FeedStore {
    
    enum ReceivedMessage: Equatable {
        case deleteCacheFeed
        case insert(items: [LocalFeedImage], timestamp: Date)
        case retrieve
    }
    
    private var deletionCompletions: [DeletionCompletion] = []
    private var insertionCompletions: [InsertionCompletion] = []
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    func deleteChachedFeeds(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCacheFeed)
    }
    
    func retrieve() {
        receivedMessages.append(.retrieve)
    }
    
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        receivedMessages.append(.insert(items: items, timestamp: timestamp))
        insertionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
}



