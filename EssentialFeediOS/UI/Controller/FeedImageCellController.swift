//
//  FeedImageCellController.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import UIKit
import EssentialFeed

public protocol FeedImageCellControllerDelegate {
    func didRequestImage()
    func didCancelImageRequest()
}

public final class FeedImageCellController: FeedImageView, ResourceView, ResourceLoadingView, ResourceErrorView {
    public typealias ResourceViewModel = UIImage
    
    private let viewModel: FeedImageViewModel<UIImage>
    private let delegate: FeedImageCellControllerDelegate
    private var cell: FeedImageCell?
    
    public init(viewModel: FeedImageViewModel<UIImage>, delegate: FeedImageCellControllerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
    }
    
    
    public func display(_ model: FeedImageViewModel<UIImage>) {}
    
    public func display(_ viewModel: ResourceViewModel) {
        cell?.feedImageView.alpha = 0
        UIView.animate(withDuration: 0.25) { [weak cell] in
            cell?.feedImageView.alpha = 1
        }
    }
    
    public func display(_ viewModel: ResourceLoadingViewModel) {
        cell?.feedImageContainer.isShimmering = viewModel.isLoading
    }
    
    public func display(_ viewModel: ResourceErrorViewModel) {
        cell?.feedImageRetryButton.isHidden = viewModel.message == nil
    }
    
    func preload() {
        delegate.didRequestImage()
    }
    
    func createCellView(in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedImageCell") as! FeedImageCell
        cell.locationContainer.isHidden = !viewModel.hasLocation
        cell.locationLabel.text = viewModel.location
        cell.descriptionLabel.text = viewModel.description
        cell.feedImageView.image = viewModel.image
        cell.onRetry = delegate.didRequestImage
        self.cell = cell
        delegate.didRequestImage()
        return cell
    }
    
    func cancelLoad() {
        cell = nil
        delegate.didCancelImageRequest()
    }
}
