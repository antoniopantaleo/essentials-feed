//
//  FeedViewController.swift
//  EssentialFeediOS
//
//  Created by Antonio on 04/03/24.
//

import UIKit
import EssentialFeed

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    
    var feedRefreshViewController: FeedRefreshViewController?
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    var tableModel: [FeedImageCellController] = [] {
        didSet { tableView.reloadData() }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = feedRefreshViewController?.view
        tableView.prefetchDataSource = self
        onViewIsAppearing = { [weak feedRefreshViewController] viewController in
            feedRefreshViewController?.refresh()
            viewController.onViewIsAppearing = nil
        }
    }
    
    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        onViewIsAppearing?(self)
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableModel.count
    }
        
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellController(forRowAt: indexPath).createCellView()
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelCellController(at: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelCellController(at:))
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(forRowAt: indexPath).preload()
        }
    }
    
    private func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        tableModel[indexPath.row]
    }
    
    private func cancelCellController(at indexPath: IndexPath) {
        tableModel[indexPath.row].cancelLoad()
    }
}
