//
//  FeedRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import UIKit
import EssentialFeed

final class FeedRefreshViewController: NSObject {
    
    private let feedLoader: FeedLoader
    var onRefresh: (([FeedImage]) -> Void)?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    lazy var view: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    @objc func refresh() {
        view.beginRefreshing()
        feedLoader.load { [weak self] feedResult in
            if case let .success(feed) = feedResult {
                self?.onRefresh?(feed)
            }
            self?.view.endRefreshing()
        }
    }
}
