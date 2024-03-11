//
//  FeedImageViewModel.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//
import Foundation
import EssentialFeed

final class FeedImageViewModel<Image> {
    typealias Observer<T> = (T) -> Void
    typealias ImageDecoder = ((Data) -> Image?)
    
    private var task: FeedImageDataLoaderTask?
    private let model: FeedImage
    private let imageLoader: FeedImageLoader
    private let imageDecoder: ImageDecoder
    
    init(model: FeedImage, imageLoader: FeedImageLoader, imageDecoder: @escaping ImageDecoder) {
        self.model = model
        self.imageLoader = imageLoader
        self.imageDecoder = imageDecoder
    }
    
    var description: String? {
        return model.description
    }
    
    var location: String?  {
        return model.location
    }
    
    var hasLocation: Bool {
        return location != nil
    }
    
    var onImageLoad: Observer<Image>?
    var onImageLoadingStateChange: Observer<Bool>?
    var onShouldRetryImageLoadStateChange: Observer<Bool>?
    
    func loadImageData() {
        onImageLoadingStateChange?(true)
        onShouldRetryImageLoadStateChange?(false)
        task = imageLoader.loadImageData(from: model.url) { [weak self] result in
            self?.handle(result)
        }
    }
    
    private func handle(_ result: FeedImageLoader.Result) {
        if let image = (try? result.get()).flatMap(imageDecoder) {
            onImageLoad?(image)
        } else {
            onShouldRetryImageLoadStateChange?(true)
        }
        onImageLoadingStateChange?(false)
    }
    
    func cancelImageDataLoad() {
        task?.cancel()
        task = nil
    }
}
