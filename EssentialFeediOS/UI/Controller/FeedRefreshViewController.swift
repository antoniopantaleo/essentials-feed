//
//  FeedRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import UIKit

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    
    var loadFeed: (() -> Void)?
    
    @IBOutlet weak var view: UIRefreshControl!
    
    @IBAction
    func refresh() {
        loadFeed?()
    }

    func display(_ viewModel: FeedLoadingViewModel) {
        viewModel.isLoading ? view.beginRefreshing() : view.endRefreshing()
    }
}
