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
    var onLoadingChange: Observer<Bool>?
    var onFeedLoad: Observer<[FeedImage]>?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        onLoadingChange?(true)
        feedLoader.load { [weak self] feedResult in
            if case let .success(feed) = feedResult {
                self?.onFeedLoad?(feed)
            }
            self?.onLoadingChange?(false)
        }
    }
}
