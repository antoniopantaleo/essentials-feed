//
//  FeedRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import UIKit

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    
    private let loadFeed: () -> Void
    
    lazy var view: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()

    init(loadFeed: @escaping () -> Void) {
        self.loadFeed = loadFeed
    }
    
    @objc func refresh() {
        loadFeed()
    }

    func display(_ viewModel: FeedLoadingViewModel) {
        viewModel.isLoading ? view.beginRefreshing() : view.endRefreshing()
    }
}
