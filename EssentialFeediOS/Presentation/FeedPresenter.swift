//
//  FeedPresenter.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import Foundation
import EssentialFeed

protocol FeedLoadingView {
    func display(isLoading: Bool)
}

protocol FeedView {
    func display(feed: [FeedImage])
}

class FeedPresenter {
    
    private let feedLoader: FeedLoader
    var feedLoadingView: FeedLoadingView?
    var feedView: FeedView?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        feedLoadingView?.display(isLoading: true)
        feedLoader.load { [weak self] feedResult in
            if case let .success(feed) = feedResult {
                self?.feedView?.display(feed: feed)
            }
            self?.feedLoadingView?.display(isLoading: false)
        }
    }
}
