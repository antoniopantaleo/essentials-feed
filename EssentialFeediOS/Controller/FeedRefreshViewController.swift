//
//  FeedRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import UIKit

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
