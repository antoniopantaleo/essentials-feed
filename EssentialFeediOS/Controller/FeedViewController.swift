//
//  FeedViewController.swift
//  EssentialFeediOS
//
//  Created by Antonio on 04/03/24.
//

import UIKit
import EssentialFeed

public enum FeedUIComposer {
     public static func feedViewController(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
         let feedRefreshViewController = FeedRefreshViewController(feedLoader: feedLoader)
         let feedViewController = FeedViewController(feedRefreshViewController: feedRefreshViewController)
         feedRefreshViewController.onRefresh = { [weak feedViewController] feed in
             feedViewController?.tableModel = feed.map { model in
                 FeedImageCellController(model: model, imageLoader: imageLoader)
             }
        }
        return feedViewController
    }
}

final class FeedImageCellController {
        
    private var task: FeedImageDataLoaderTask?
    private let model: FeedImage
    private let imageLoader: FeedImageLoader
    
    init(model: FeedImage, imageLoader: FeedImageLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    func preload() {
        task = imageLoader.loadImageData(from: model.url) { _ in }
    }
    
    func createCellView() -> UITableViewCell {
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = model.location == nil
        cell.descriptionLabel.text = model.description
        cell.feedImageView.image = nil
        cell.feedImageRetryButton.isHidden = true
        cell.locationLabel.text = model.location
        cell.feedImageContainer.startShimmering()
        let loadImage = { [weak self, weak cell] in
            guard let self else { return }
            task = imageLoader.loadImageData(from: model.url) { result in
                switch result {
                    case let .success(imageData):
                        cell?.feedImageRetryButton.isHidden = !imageData.isEmpty
                        guard let decodedImage = UIImage(data: imageData) else { fallthrough }
                        cell?.feedImageView.image = decodedImage
                    case .failure:
                        cell?.feedImageRetryButton.isHidden = false
                }
                cell?.feedImageContainer.stopShimmering()
            }
        }
        cell.onRetry = loadImage
        loadImage()
        return cell
    }
    
    func cancelLoad() {
        task?.cancel()
    }
}

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    
    var feedRefreshViewController: FeedRefreshViewController?
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    var tableModel: [FeedImageCellController] = [] {
        didSet { tableView.reloadData() }
    }
    
    convenience init(feedRefreshViewController: FeedRefreshViewController) {
        self.init()
        self.feedRefreshViewController = feedRefreshViewController
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
