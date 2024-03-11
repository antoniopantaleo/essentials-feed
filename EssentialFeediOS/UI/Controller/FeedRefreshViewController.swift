//
//  FeedRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import UIKit

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    
    private let feedPresenter: FeedPresenter

    init(feedPresenter: FeedPresenter) {
        self.feedPresenter = feedPresenter
    }
    
    lazy var view: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    @objc func refresh() {
        feedPresenter.loadFeed()
    }

    func display(isLoading: Bool) {
        isLoading ? view.beginRefreshing() : view.endRefreshing()
    }
}
