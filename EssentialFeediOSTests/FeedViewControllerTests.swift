//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Antonio Pantaleo on 03/03/24.
//

import XCTest
import UIKit
import EssentialFeed
import EssentialFeediOS

final class FeedViewControllerTests: XCTestCase {
    
    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_viewDidLoad_loadsFeed() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    func test_userInitiatedFeedReload_loadsFeed() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        
        sut.simulateUserInitiatedFeedReload()
        
        XCTAssertEqual(loader.loadCallCount, 2)
    }
    
    func test_refreshControl_showsAndHidesBasedOnLoadingState() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        
        loader.completeFeedLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator)
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        
        loader.completeFeedLoadingWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }
    
    func test_loadFeedCompletion_rendersSuccesfullyLoadedFeed() throws {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        try assertThat(sut, isRendering: [])
        
        loader.completeFeedLoading(with: [image0])
        try assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(with: [image0, image1, image2, image3], at: 1)
        try assertThat(sut, isRendering: [image0, image1, image2, image3])
    }
    
    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() throws {
        let image0 = makeImage()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance  ()
        loader.completeFeedLoading(with: [image0], at: 0)
        try assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoadingWithError(at: 1)
        try assertThat(sut, isRendering: [image0])
    }
    
    func test_feedImageView_loadsImageURLWhenVisible() {
        let image0 = makeImage(url: URL(string: "http://image0.com")!)
        let image1 = makeImage(url: URL(string: "http://image1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loader.loadedImageURLs, [])
        
        sut.simulateViewVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url])
        
        sut.simulateViewVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url])
    }
    
    func test_feedImageView_cancelsImageURLWhenNotVisibleAnymore() {
        let image0 = makeImage(url: URL(string: "http://image0.com")!)
        let image1 = makeImage(url: URL(string: "http://image1.com")!)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        
        loader.completeFeedLoading(with: [image0, image1])
        XCTAssertEqual(loader.cancelledImageURLs, [])
        
        sut.simulateViewNotVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [image0.url])
        
        sut.simulateViewNotVisible(at: 1)
        XCTAssertEqual(loader.cancelledImageURLs, [image0.url, image1.url])
    }
    
    func test_feedImageViewLoadingIndicator_isVisibleWhileLoadingImage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateViewVisible(at: 0)
        let view1 = sut.simulateViewVisible(at: 1)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, true, "Expected loading indicator for first view while loading first image")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true, "Expected loading indicator for second view while loading second image")
        
        loader.completeImageLoading(at: 0)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, false, "Expected no loading indicator for first view once first image loading completes successfully")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true, "Expected no loading indicator state change for second view once first image loading completes successfully")
        
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, false, "Expected no loading indicator state change for first view once second image loading completes with error")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, false, "Expected no loading indicator for second view once second image loading completes with error")
    }
    
    func test_feedImageView_rendersImageLoadedFromURL() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateViewVisible(at: 0)
        let view1 = sut.simulateViewVisible(at: 1)
        XCTAssertEqual(view0?.renderedImage, .none, "Expected no image for first view while loading first image")
        XCTAssertEqual(view1?.renderedImage, .none, "Expected no image for second view while loading second image")
        
        let imageData0 = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData0, at: 0)
        XCTAssertEqual(view0?.renderedImage, imageData0, "Expected image for first view once first image loading completes successfully")
        XCTAssertEqual(view1?.renderedImage, .none, "Expected no image state change for second view once first image loading completes successfully")
        
        let imageData1 = UIImage.make(withColor: .blue).pngData()!
        loader.completeImageLoading(with: imageData1, at: 1)
        XCTAssertEqual(view0?.renderedImage, imageData0, "Expected no image state change for first view once second image loading completes successfully")
        XCTAssertEqual(view1?.renderedImage, imageData1, "Expected image for second view once second image loading completes successfully")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(feedLoader: loader, imageLoader: loader)
        trackMemoryLeaks(loader, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func assertThat(
        _ sut: FeedViewController,
        hasViewConfiguredFor image: FeedImage,
        at index: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let view = try XCTUnwrap(sut.feedImageView(at: index))
        
        guard let cell = view as? FeedImageCell else {
            return XCTFail("Expected \(FeedImageCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
        }
        
        let shouldLocationBeVisible = (image.location != nil)
        XCTAssertEqual(cell.isShowingLocation, shouldLocationBeVisible, "Expected `isShowingLocation` to be \(shouldLocationBeVisible) for image view at index (\(index))", file: file, line: line)
        
        XCTAssertEqual(cell.locationText, image.location, "Expected location text to be \(String(describing: image.location)) for image  view at index (\(index))", file: file, line: line)
        
        XCTAssertEqual(cell.descriptionText, image.description, "Expected description text to be \(String(describing: image.description)) for image view at index (\(index)", file: file, line: line)
    }
    
    private func assertThat(
        _ sut: FeedViewController,
        isRendering feed: [FeedImage],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        guard sut.numberOfRenderedFeedImageViews == feed.count else {
            return XCTFail("Expected \(feed.count) images, got \(sut.numberOfRenderedFeedImageViews) instead.", file: file, line: line)
        }
        try feed.enumerated().forEach { index, image in
            try assertThat(sut, hasViewConfiguredFor: image, at: index, file: file, line: line)
        }
    }
    
    private func makeImage(
        description: String? = nil,
        location: String? = nil,
        url: URL = URL(string: "http://any-url.com")!
    ) -> FeedImage {
        FeedImage(
            id: UUID(),
            description: description,
            location: location,
            url: url
        )
    }
    
    class LoaderSpy: FeedLoader, FeedImageLoader {
        
        struct TaskSpy: FeedImageDataLoaderTask {
            var onCancel: (() -> Void)
            func cancel() {
                onCancel()
            }
        }
        
        typealias LoadCompletion = ((LoadFeedResult) -> Void)
        private var completions = [LoadCompletion]()
        private var imageRequests = [(url: URL, completion: (FeedImageLoader.Result) -> Void)]()
        
        var loadCallCount: Int  { completions.count }
        var loadedImageURLs: [URL] { imageRequests.map { $0.url } }
        private(set) var cancelledImageURLs = [URL]()
        
        func completeFeedLoadingWithError(at index: Int = 0) {
            let error = NSError(domain: "an error", code: 0)
            completions[index](.failure(error))
        }
        
        func completeFeedLoading(with feed: [FeedImage] = [], at index: Int = 0) {
            completions[index](.success(feed))
        }
        
        func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) {
            imageRequests[index].completion(.success(imageData))
        }
        
        func completeImageLoadingWithError(at index: Int = 0) {
            let error = NSError(domain: "an error", code: 0)
            imageRequests[index].completion(.failure(error))
        }
        
        func load(completion: @escaping (LoadFeedResult) -> Void) {
            completions.append(completion)
        }
        
        func loadImageData(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void)  -> FeedImageDataLoaderTask {
            imageRequests.append((url, completion))
            return TaskSpy { [weak self] in
                self?.cancelledImageURLs.append(url)
            }
        }
    }
    
}
