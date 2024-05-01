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
        let feedLoaderPresentationAdapter = LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapter>(
            loader: feedLoader
        )
        let feedViewController = FeedViewController.makeWith(
            loadFeed: feedLoaderPresentationAdapter.loadResource,
            title: FeedPresenter.title
        )
        feedLoaderPresentationAdapter.presenter = LoadResourcePresenter(
            resourceView: FeedViewAdapter(
                controller: feedViewController,
                imageLoader: { imageLoader($0).dispatchOnMainQueue() }
            ),
            loadingView: WeakRefProxy(feedViewController),
            errorView: WeakRefProxy(feedViewController),
            mapper: FeedPresenter.map
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

extension WeakRefProxy: ResourceView where T: ResourceView, T.ResourceViewModel == UIImage {
    func display(_ viewModel: UIImage) {
        instance?.display(viewModel)
    }
}

extension WeakRefProxy: ResourceErrorView where T: ResourceErrorView {
    func display(_ viewModel: ResourceErrorViewModel) {
        instance?.display(viewModel)
    }
}

private final class FeedViewAdapter: ResourceView {
    
    private weak var controller: FeedViewController?
    private let imageLoader: (URL) -> FeedImageLoader.Publisher
    
    init(controller: FeedViewController, imageLoader: @escaping (URL) -> FeedImageLoader.Publisher) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { model in
            let adapter = LoadResourcePresentationAdapter<Data, WeakRefProxy<FeedImageCellController>> { [imageLoader] in
                imageLoader(model.url)
            }
            let view = FeedImageCellController(
                viewModel: FeedImagePresenter.map(model),
                delegate: adapter
            )
            
            adapter.presenter = LoadResourcePresenter(
                resourceView: WeakRefProxy(view),
                loadingView: WeakRefProxy(view),
                errorView: WeakRefProxy(view),
                mapper: { data in
                    guard let image = UIImage(data: data) else {
                        throw InvalidImageDataError()
                    }
                    return image
                }
            )
            return view
        }
    }
}
private struct InvalidImageDataError: Error {}

private final class LoadResourcePresentationAdapter<Resource, View: ResourceView> {
    private let loader: () -> AnyPublisher<Resource, Error>
    var presenter: LoadResourcePresenter<Resource, View>?
    private var cancellable: AnyCancellable?
    
    init(loader: @escaping () -> AnyPublisher<Resource, Error>) {
        self.loader = loader
    }
    
    func loadResource() {
        presenter?.didStartLoading()
        cancellable = loader().sink(
            receiveCompletion: { [weak presenter] completion in
                if case let .failure(error) = completion {
                    presenter?.didFinishLoading(with: error)
                }
            },
            receiveValue: { [weak presenter] resource in
                presenter?.didFinishLoading(with: resource)
            }
        )
    }
}

extension LoadResourcePresentationAdapter: FeedImageCellControllerDelegate {
    func didRequestImage() {
        loadResource()
    }
    
    func didCancelImageRequest() {
        cancellable?.cancel()
        cancellable = nil
    }
}
