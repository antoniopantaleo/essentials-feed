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
    
    var feedLoadingView: FeedLoadingView?
    var feedView: FeedView?
    
    func didStartLoadingFeed() {
        feedLoadingView?.display(FeedLoadingViewModel(isLoading: true))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView?.display(FeedViewModel(feed: feed))
        feedLoadingView?.display(FeedLoadingViewModel(isLoading: false))
    }
    
    func didFinishLoadingFeed(withError error: Error) {
        feedLoadingView?.display(FeedLoadingViewModel(isLoading: false))
    }
    
}
