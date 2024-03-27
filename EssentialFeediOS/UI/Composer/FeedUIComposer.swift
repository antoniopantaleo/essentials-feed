//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import EssentialFeediOS
import EssentialFeed
import UIKit

public enum FeedUIComposer {
    public static func feedViewController(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        let feedLoaderPresentationAdapter = FeedLoaderPresentationAdapter(
            feedLoader: MainQueueDispatchDecorator(decoratee: feedLoader)
        )
        let feedViewController = FeedViewController.makeWith(
            loadFeed: feedLoaderPresentationAdapter.loadFeed,
            title: FeedPresenter.title
        )
        feedLoaderPresentationAdapter.feedPresenter = FeedPresenter(
            feedView: FeedImageCellControllerAdapter(
                controller: feedViewController,
                imageLoader: MainQueueDispatchDecorator(decoratee: imageLoader)
            ),
            loadingView: WeakRefProxy(feedViewController),
            errorView: WeakRefProxy(feedViewController)
        )
        return feedViewController
    }
}

private extension FeedViewController {
    static func makeWith(loadFeed: @escaping () -> Void, title: String) -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let feedController = storyboard.instantiateInitialViewController() as! FeedViewController
        feedController.loadFeed = loadFeed
        feedController.title = title
        return feedController
    }
}


private final class MainQueueDispatchDecorator<T> {
    private let decoratee: T
    
    init(decoratee: T) {
        self.decoratee = decoratee
    }
    
    func dispatch(completion: @escaping () -> Void) {
        guard Thread.isMainThread else {
            return DispatchQueue.main.async(execute: completion)
        }
        
        completion()
    }
}

extension MainQueueDispatchDecorator: FeedLoader where T == FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void) {
        decoratee.load { [weak self] result in
            self?.dispatch { completion(result) }
        }
    }
}

extension MainQueueDispatchDecorator: FeedImageLoader where T == FeedImageLoader {
    func loadImageData(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        return decoratee.loadImageData(from: url) { [weak self] result in
            self?.dispatch { completion(result) }
        }
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

extension WeakRefProxy: FeedErrorView where T: FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel) {
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
                    feedPresenter?.didFinishLoadingFeed(with: error)
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
