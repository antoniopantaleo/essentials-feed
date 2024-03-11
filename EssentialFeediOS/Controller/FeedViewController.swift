//
//  FeedViewController.swift
//  EssentialFeediOS
//
//  Created by Antonio on 04/03/24.
//

import UIKit
import EssentialFeed

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
    
    deinit {
        task?.cancel()
    }
}

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    
    var feedRefreshViewController: FeedRefreshViewController?
    private var imageLoader: FeedImageLoader?
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var tableModel: [FeedImage] = [] {
        didSet { tableView.reloadData() }
    }
    private var cellControllers = [IndexPath: FeedImageCellController]()
    
    public convenience init(feedLoader: FeedLoader, imageLoader: FeedImageLoader) {
        self.init()
        self.feedRefreshViewController = FeedRefreshViewController(feedLoader: feedLoader)
        self.imageLoader = imageLoader
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = feedRefreshViewController?.view
        feedRefreshViewController?.onRefresh = { [weak self] feed in
            self?.tableModel = feed
        }
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
        removeCellController(at: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(removeCellController(at:))
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(forRowAt: indexPath).preload()
        }
    }
    
    fileprivate func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        let cellModel = tableModel[indexPath.row]
        let cellController = FeedImageCellController(model: cellModel, imageLoader: imageLoader!)
        cellControllers[indexPath] = cellController
        return cellController
    }
    
    private func removeCellController(at indexPath: IndexPath) {
        cellControllers[indexPath] = nil
    }
}
