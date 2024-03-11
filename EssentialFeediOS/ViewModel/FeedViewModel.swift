//
//  FeedViewModel.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import Foundation
import EssentialFeed

final class FeedViewModel {
    
    typealias Observer<T> = ((T) -> Void)
    
    private let feedLoader: FeedLoader
    var onChange: Observer<FeedViewModel>?
    var onFeedLoad: Observer<[FeedImage]>?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    private(set) var isLoading: Bool = true {
        didSet { onChange?(self) }
    }
    
    func loadFeed() {
        isLoading = true
        feedLoader.load { [weak self] feedResult in
            if case let .success(feed) = feedResult {
                self?.onFeedLoad?(feed)
            }
            self?.isLoading = false
        }
    }
}
