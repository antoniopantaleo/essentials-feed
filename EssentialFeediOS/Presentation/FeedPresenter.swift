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

struct FeedErrorViewModel {
    let message: String?
}

protocol FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel)
}

class FeedPresenter {
    
    private let feedLoadingView: FeedLoadingView
    private let feedView: FeedView
    private let feedErrorView: FeedErrorView
    
    static var title: String {
        NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "Title for the feed view"
        )
    }
    
    private var feedLoadError: String {
        return NSLocalizedString(
            "FEED_VIEW_CONNECTION_ERROR",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "Error message displayed when we can't load the image feed from the server"
        )
    }
    
    init(feedLoadingView: FeedLoadingView, feedView: FeedView, feedErrorView: FeedErrorView) {
        self.feedLoadingView = feedLoadingView
        self.feedView = feedView
        self.feedErrorView = feedErrorView
    }
    
    func didStartLoadingFeed() {
        feedErrorView.display(FeedErrorViewModel(message: nil))
        feedLoadingView.display(FeedLoadingViewModel(isLoading: true))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
        feedLoadingView.display(FeedLoadingViewModel(isLoading: false))
    }
    
    func didFinishLoadingFeed(withError error: Error) {
        feedErrorView.display(FeedErrorViewModel(message: feedLoadError))
        feedLoadingView.display(FeedLoadingViewModel(isLoading: false))
    }
    
}
