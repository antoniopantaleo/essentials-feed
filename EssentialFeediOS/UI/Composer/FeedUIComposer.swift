//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import EssentialFeediOS
import EssentialFeed
import Combine
import UIKit

public enum FeedUIComposer {
    static func feedViewController(
        feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>,
        imageLoader: @escaping (URL) -> FeedImageLoader.Publisher
    ) -> FeedViewController {
        let feedLoaderPresentationAdapter = FeedLoaderPresentationAdapter(
            feedLoader: { feedLoader().dispatchOnMainQueue() }
        )
        let feedViewController = FeedViewController.makeWith(
            loadFeed: feedLoaderPresentationAdapter.loadFeed,
            title: FeedPresenter.title
        )
        feedLoaderPresentationAdapter.feedPresenter = FeedPresenter(
            feedView: FeedImageCellControllerAdapter(
                controller: feedViewController,
                imageLoader: { imageLoader($0).dispatchOnMainQueue() }
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


private final class WeakRefProxy<T: AnyObject> {
    private weak var instance: T?
    
    init(_ instance: T) {
        self.instance = instance
    }
}

extension WeakRefProxy: ResourceLoadingView where T: ResourceLoadingView {
    func display(_ viewModel: ResourceLoadingViewModel) {
        instance?.display(viewModel)
    }
}

extension WeakRefProxy: FeedImageView where T: FeedImageView, T.Image == UIImage {
    func display(_ viewModel: FeedImageViewModel<UIImage>) {
        instance?.display(viewModel)
    }
}

extension WeakRefProxy: ResourceErrorView where T: ResourceErrorView {
    func display(_ viewModel: ResourceErrorViewModel) {
        instance?.display(viewModel)
    }
}

private final class FeedImageCellControllerAdapter: FeedView {
    
    private weak var controller: FeedViewController?
    private let imageLoader: (URL) -> FeedImageLoader.Publisher
    
    init(controller: FeedViewController, imageLoader: @escaping (URL) -> FeedImageLoader.Publisher) {
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
    private let feedLoader: () -> AnyPublisher<[FeedImage], Error>
    var feedPresenter: FeedPresenter?
    private var cancellable: AnyCancellable?
    
    init(feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        feedPresenter?.didStartLoadingFeed()
        cancellable = feedLoader().sink(
            receiveCompletion: { [weak feedPresenter] completion in
                if case let .failure(error) = completion {
                    feedPresenter?.didFinishLoadingFeed(with: error)
                }
            },
            receiveValue: { [weak feedPresenter] feed in
                feedPresenter?.didFinishLoadingFeed(with: feed)
            }
        )
    }
}

private final class FeedImageLoaderPresentationAdapter<View: FeedImageView, Image>: FeedImageCellControllerDelegate where View.Image == Image {
    private let model: FeedImage
    private let imageLoader: (URL) -> FeedImageLoader.Publisher
    private var cancellable: AnyCancellable?
    
    var presenter: FeedImagePresenter<View, Image>?
    
    init(model: FeedImage, imageLoader: @escaping (URL) -> FeedImageLoader.Publisher) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    func didRequestImage() {
        presenter?.didStartLoadingImageData(for: model)
        let model = self.model
        cancellable = imageLoader(model.url).sink(
            receiveCompletion: { [weak presenter] completion in
                if case let .failure(error) = completion {
                    presenter?.didFinishLoadingImageData(with: error, for: model)
                }
            },
            receiveValue: { [weak presenter] data in
                presenter?.didFinishLoadingImageData(with: data, for: model)
            }
        )
    }
    
    func didCancelImageRequest() {
        cancellable?.cancel()
    }
}
