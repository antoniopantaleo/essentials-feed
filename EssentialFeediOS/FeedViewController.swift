//
//  FeedViewController.swift
//  EssentialFeediOS
//
//  Created by Antonio on 04/03/24.
//

import UIKit
import EssentialFeed

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageLoader {
    typealias Result = Swift.Result<Data, Error>
    func loadImageData(from url: URL, completion: @escaping (Result) -> Void) -> FeedImageDataLoaderTask
}

public final class FeedViewController: UITableViewController {
    
    private var feedLoader: FeedLoader?
    private var imageLoader: FeedImageLoader?
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var tableModel: [FeedImage] = []
    private var tasks = [IndexPath: FeedImageDataLoaderTask]()
    
    public convenience init(feedLoader: FeedLoader, imageLoader: FeedImageLoader) {
        self.init()
        self.feedLoader = feedLoader
        self.imageLoader = imageLoader
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        onViewIsAppearing = { viewController in
            viewController.load()
            viewController.onViewIsAppearing = nil
        }
    }
    
    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        onViewIsAppearing?(self)
    }
    
    @objc private func load() {
        refreshControl?.beginRefreshing()
        feedLoader?.load { [weak self, refreshControl] feedResult in
            if case let .success(feed) = feedResult {
                self?.tableModel = feed
            }
            refreshControl?.endRefreshing()
        }
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = tableModel[indexPath.row]
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = model.location == nil
        cell.descriptionLabel.text = model.description
        cell.feedImageView.image = nil
        cell.feedImageRetryButton.isHidden = true
        cell.locationLabel.text = model.location
        cell.feedImageContainer.startShimmering()
        tasks[indexPath] = imageLoader?.loadImageData(from: model.url) { result in
            switch result {
                case let .success(imageData):
                    cell.feedImageRetryButton.isHidden = !imageData.isEmpty
                    cell.feedImageView.image = UIImage(data: imageData)
                case .failure:
                    cell.feedImageRetryButton.isHidden = false
            }
            cell.feedImageContainer.stopShimmering()
        }
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
}
