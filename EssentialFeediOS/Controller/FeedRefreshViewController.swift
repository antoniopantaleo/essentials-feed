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
    var onFeedLoad: Observer<[FeedImage]>?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    private(set) var isLoading: Bool = true {
        didSet { onChange?(self) }
    }
    
    func loadFeed() {
        isLoading = true
        feedLoader.load { [weak self] feedResult in
            if case let .success(feed) = feedResult {
                self?.onFeedLoad?(feed)
            }
            self?.isLoading = false
        }
    }
}

final class FeedRefreshViewController: NSObject {
    
    private let viewModel: FeedViewModel

    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }
    
    lazy var view: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    @objc func refresh() {
        viewModel.onChange = { [weak view] viewModel in
            viewModel.isLoading ? view?.beginRefreshing() : view?.endRefreshing()
        }
        viewModel.loadFeed()
    }
}
