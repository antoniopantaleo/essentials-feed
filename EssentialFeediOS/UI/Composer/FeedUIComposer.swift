//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import Foundation
import EssentialFeed
import UIKit

public enum FeedUIComposer {
    public static func feedViewController(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        let feedPresenter = FeedPresenter(feedLoader: feedLoader)
        let feedRefreshViewController = FeedRefreshViewController(loadFeed: feedPresenter.loadFeed)
        let feedViewController = FeedViewController(feedRefreshViewController: feedRefreshViewController)
        feedPresenter.feedLoadingView = WeakRefProxy(feedRefreshViewController)
        feedPresenter.feedView = FeedImageCellControllerAdapter(controller: feedViewController, imageLoader: imageLoader)
        return feedViewController
    }
}

private final class WeakRefProxy<T: AnyObject> {
    private weak var instance: T?
    
    init(_ instance: T) {
        self.instance = instance
    }
}

extension WeakRefProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        instance?.display(viewModel)
    }
}

private final class FeedImageCellControllerAdapter: FeedView {
    
    private weak var controller: FeedViewController?
    private let imageLoader: FeedImageLoader
    
    init(controller: FeedViewController, imageLoader: FeedImageLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { model in
            let viewModel = FeedImageViewModel<UIImage>(model: model, imageLoader: imageLoader, imageDecoder: UIImage.init(data:))
            return FeedImageCellController(viewModel: viewModel)
        }
    }
}
