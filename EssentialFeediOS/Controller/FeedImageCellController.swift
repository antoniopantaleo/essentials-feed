//
//  FeedImageCellController.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import UIKit

final class FeedImageCellController {
    
    private let viewModel: FeedImageViewModel
    
    init(viewModel: FeedImageViewModel) {
        self.viewModel = viewModel
    }
    
    func preload() {
        viewModel.loadImageData()
    }
    
    func createCellView() -> UITableViewCell {
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = !viewModel.hasLocation
        cell.locationLabel.text = viewModel.location
        cell.descriptionLabel.text = viewModel.description
        cell.onRetry = viewModel.loadImageData
        
        viewModel.onShouldRetryImageLoadStateChange = { [weak cell] shouldRetry in
            cell?.feedImageRetryButton.isHidden = !shouldRetry
        }
        viewModel.onImageLoad = { [weak cell] image in
            cell?.feedImageView.image = image
        }
        viewModel.onImageLoadingStateChange = { [weak cell] isLoading in
            cell?.feedImageContainer.isShimmering = isLoading
        }
        viewModel.loadImageData()
        return cell
    }
    
    func cancelLoad() {
        viewModel.cancelImageDataLoad()
    }
}
