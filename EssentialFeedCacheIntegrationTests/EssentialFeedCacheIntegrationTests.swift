//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Antonio on 02/03/24.
//

import XCTest
import EssentialFeed

final class EssentialFeedCacheIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }
    
    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeFeedLoader()
        expect(sut, toLoad: [])
    }
    
    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeFeedLoader()
        let sutToPerformLoad = makeFeedLoader()
        let feed = uniqueImageFeed().items
        
        save(feed, with: sutToPerformSave)
        
        expect(sutToPerformLoad, toLoad: feed)
    }
    
    func test_save_overridesItemsSavedOnASeparateInstance() {
        let sutToPerformFirstSave = makeFeedLoader()
        let sutToPerformLastSave = makeFeedLoader()
        let sutToPerformLoad = makeFeedLoader()
        let firstFeed = uniqueImageFeed().items
        let latestFeed = uniqueImageFeed().items
        
        save(firstFeed, with: sutToPerformFirstSave)
        save(latestFeed, with: sutToPerformLastSave)
        
        expect(sutToPerformLoad, toLoad: latestFeed)
    }
    
    func test_loadImageData_deliversSavedDataOnASeparateInstance() {
        let imageLoaderToPerformSave = makeImageLoader()
        let imageLoaderToPerformLoad = makeImageLoader()
        let feedLoader = makeFeedLoader()
        let image = uniqueImage()
        let dataToSave = Data("any data".utf8)
        
        save([image], with: feedLoader)
        save(dataToSave, for: image.url, with: imageLoaderToPerformSave)
        
        expect(imageLoaderToPerformLoad, toLoad: dataToSave, for: image.url)
    }
    
    func test_saveImageData_overridesSavedImageDataOnASeparateInstance() {
        let imageLoaderToPerformFirstSave = makeImageLoader()
        let imageLoaderToPerformLastSave = makeImageLoader()
        let imageLoaderToPerformLoad = makeImageLoader()
        let feedLoader = makeFeedLoader()
        let image = uniqueImage()
        let firstImageData = Data("first".utf8)
        let lastImageData = Data("last".utf8)
        
        save([image], with: feedLoader)
        save(firstImageData, for: image.url, with: imageLoaderToPerformFirstSave)
        save(lastImageData, for: image.url, with: imageLoaderToPerformLastSave)
        
        expect(imageLoaderToPerformLoad, toLoad: lastImageData, for: image.url)
    }
    
    func test_validateFeedCache_doesNotDeleteRecentlySavedFeed() {
        let feedLoaderToPerformSave = makeFeedLoader()
        let feedLoaderToPerformValidation = makeFeedLoader()
        let feed = uniqueImageFeed().items
        
        save(feed, with: feedLoaderToPerformSave)
        validateCache(with: feedLoaderToPerformValidation)
        
        expect(feedLoaderToPerformSave, toLoad: feed)
    }
    
    func test_validateFeedCache_deletesFeedSavedInADistantPast() {
        let feedLoaderToPerformSave = makeFeedLoader(currentDate: .distantPast)
        let feedLoaderToPerformValidation = makeFeedLoader(currentDate: Date())
        let feed = uniqueImageFeed().items
        
        save(feed, with: feedLoaderToPerformSave)
        validateCache(with: feedLoaderToPerformValidation)
        
        expect(feedLoaderToPerformSave, toLoad: [])
    }

    
    // MARK: Helpers
    private func makeFeedLoader(currentDate: Date = Date(), file: StaticString = #file, line: UInt = #line) -> LocalFeedLoader {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalFeedLoader(store: store, currentDate: { currentDate })
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func makeImageLoader(file: StaticString = #file, line: UInt = #line) -> LocalFeedImageLoader {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalFeedImageLoader(store: store)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func validateCache(with loader: LocalFeedLoader, file: StaticString = #file, line: UInt = #line) {
        let saveExp = expectation(description: "Wait for save completion")
        loader.validateCache() { result in
            if case let Result.failure(error) = result {
                XCTFail("Expected to validate feed successfully, got error: \(error)", file: file, line: line)
            }
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1.0)
    }
    
    private func save(_ feed: [FeedImage], with loader: LocalFeedLoader, file: StaticString = #file, line: UInt = #line) {
        let saveExp = expectation(description: "Wait for save completion")
        loader.save(feed) { saveResult in
            if case .failure = saveResult {
                XCTFail("Expected to save feed successfully", file: file, line: line)
            }
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1.0)
    }
    
    private func expect(_ sut: LocalFeedLoader, toLoad expectedFeed: [FeedImage], file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            switch result {
                case let .success(loadedFeed):
                    XCTAssertEqual(loadedFeed, expectedFeed, file: file, line: line)
                    
                case let .failure(error):
                    XCTFail("Expected successful feed result, got \(error) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func save(_ data: Data, for url: URL, with loader: LocalFeedImageLoader, file: StaticString = #file, line: UInt = #line) {
        let saveExp = expectation(description: "Wait for save completion")
        loader.save(data, for: url) { result in
            if case let Result.failure(error) = result {
                XCTFail("Expected to save image data successfully, got error: \(error)", file: file, line: line)
            }
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1.0)
    }
    
    private func expect(_ sut: LocalFeedImageLoader, toLoad expectedData: Data, for url: URL, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        _ = sut.loadImageData(from: url) { result in
            switch result {
                case let .success(loadedData):
                    XCTAssertEqual(loadedData, expectedData, file: file, line: line)
                    
                case let .failure(error):
                    XCTFail("Expected successful image data result, got \(error) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
