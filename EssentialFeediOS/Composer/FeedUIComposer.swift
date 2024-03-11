//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//

import Foundation
import EssentialFeed

public enum FeedUIComposer {
    public static func feedViewController(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        let feedRefreshViewController = FeedRefreshViewController(feedLoader: feedLoader)
        let feedViewController = FeedViewController(feedRefreshViewController: feedRefreshViewController)
        feedRefreshViewController.onRefresh = { [weak feedViewController] feed in
            feedViewController?.tableModel = FeedImageCellControllerAdapter.adapt(feed: feed, imageLoader: imageLoader)
        }
        return feedViewController
    }
}

private enum FeedImageCellControllerAdapter {
    static func adapt(feed: [FeedImage], imageLoader: FeedImageLoader) -> [FeedImageCellController] {
        feed.map { model in
            FeedImageCellController(model: model, imageLoader: imageLoader)
        }
    }
}
