//
//  FeedRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import UIKit
import EssentialFeed

final class FeedViewModel {
    
    typealias Observer<T> = ((T) -> Void)
    
    private let feedLoader: FeedLoader
    var onChange: Observer<FeedViewModel>?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    private enum State {
        case pending
        case loading
        case loaded([FeedImage])
        case failed
    }
    
    private var state = State.pending {
        didSet { onChange?(self) }
    }
    
    var isLoading: Bool {
        guard case .loading = state else { return false }
        return true
    }
    var feed: [FeedImage]? {
        guard case let .loaded(feed) = state else { return nil }
        return feed
    }
    
    func loadFeed() {
        state = .loading
        feedLoader.load { [weak self] feedResult in
            if case let .success(feed) = feedResult {
                self?.state = .loaded(feed)
            } else {
                self?.state = .failed
            }
        }
    }
}

final class FeedRefreshViewController: NSObject {
    
    private let viewModel: FeedViewModel
    var onRefresh: (([FeedImage]) -> Void)?

    init(feedLoader: FeedLoader) {
        viewModel = FeedViewModel(feedLoader: feedLoader)
    }
    
    lazy var view: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    @objc func refresh() {
        viewModel.onChange = { [weak self, weak view] viewModel in
            viewModel.isLoading ? view?.beginRefreshing() : view?.endRefreshing()
            if let feed = viewModel.feed {
                self?.onRefresh?(feed)
            }
        }
        viewModel.loadFeed()
    }
}
