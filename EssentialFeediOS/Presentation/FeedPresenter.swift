//
//  FeedPresenter.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import Foundation
import EssentialFeed

struct FeedLoadingViewModel {
    var isLoading: Bool
}

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

struct FeedViewModel {
    var feed: [FeedImage]
}

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

class FeedPresenter {
    
    private let feedLoader: FeedLoader
    var feedLoadingView: FeedLoadingView?
    var feedView: FeedView?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        feedLoadingView?.display(FeedLoadingViewModel(isLoading: true))
        feedLoader.load { [weak self] feedResult in
            if case let .success(feed) = feedResult {
                self?.feedView?.display(FeedViewModel(feed: feed))
            }
            self?.feedLoadingView?.display(FeedLoadingViewModel(isLoading: false))
        }
    }
}
