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
        let feedLoaderPresentationAdapter = FeedLoaderPresentationAdapter(feedLoader: feedLoader)
        let feedRefreshViewController = FeedRefreshViewController(loadFeed: feedLoaderPresentationAdapter.loadFeed)
        let feedViewController = FeedViewController(feedRefreshViewController: feedRefreshViewController)
        feedLoaderPresentationAdapter.feedPresenter = FeedPresenter(
            feedLoadingView: WeakRefProxy(feedRefreshViewController),
            feedView: FeedImageCellControllerAdapter(
                controller: feedViewController,
                imageLoader: imageLoader
            )
        )
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

extension WeakRefProxy: FeedImageView where T: FeedImageView, T.Image == UIImage {
    func display(_ viewModel: FeedImageViewModel<UIImage>) {
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
            let adapter = FeedImageLoaderPresentationAdapter<WeakRefProxy<FeedImageCellController>, UIImage>(
                model: model,
                imageLoader: imageLoader
            )
            let view = FeedImageCellController(delegate: adapter)
            adapter.presenter = FeedImagePresenter(
                view: WeakRefProxy(view),
                imageTransformer: UIImage.init(data:)
            )
            return view
        }
    }
}

private final class FeedLoaderPresentationAdapter {
    private let feedLoader: FeedLoader
    var feedPresenter: FeedPresenter?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        feedPresenter?.didStartLoadingFeed()
        feedLoader.load { [weak feedPresenter] result in
            switch result {
                case let .success(feed):
                    feedPresenter?.didFinishLoadingFeed(with: feed)
                case let .failure(error):
                    feedPresenter?.didFinishLoadingFeed(withError: error)
            }
        }
    }
}

private final class FeedImageLoaderPresentationAdapter<View: FeedImageView, Image>: FeedImageCellControllerDelegate where View.Image == Image {
    private let model: FeedImage
    private let imageLoader: FeedImageLoader
    private var task: FeedImageDataLoaderTask?
    
    var presenter: FeedImagePresenter<View, Image>?
    
    init(model: FeedImage, imageLoader: FeedImageLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    func didRequestImage() {
        presenter?.didStartLoadingImageData(for: model)
        
        let model = self.model
        task = imageLoader.loadImageData(from: model.url) { [weak presenter] result in
            switch result {
                case let .success(data):
                    presenter?.didFinishLoadingImageData(with: data, for: model)
                case let .failure(error):
                    presenter?.didFinishLoadingImageData(with: error, for: model)
            }
        }
    }
    
    func didCancelImageRequest() {
        task?.cancel()
    }
}
