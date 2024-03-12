//
//  FeedViewController+Extensions.swift
//  EssentialFeediOSTests
//
//  Created by Antonio on 04/03/24.
//

import UIKit
@testable import EssentialFeediOS

extension FeedViewController {
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }
    
    var numberOfRenderedFeedImageViews: Int {
        tableView(tableView, numberOfRowsInSection: feedImageSection)
    }
    
    var errorMessage: String? {
        errorView?.message
    }
    
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            swapRefreshControlForIOS17Support()
        }
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    @discardableResult
    func simulateViewVisible(at index: Int) -> FeedImageCell? {
        feedImageView(at: index) as? FeedImageCell
    }
    
    @discardableResult
    func simulateFeedImageViewNotVisible(at row: Int) -> FeedImageCell? {
        let view = simulateViewVisible(at: row)
        let index = IndexPath(row: row, section: feedImageSection)
        tableView(tableView, didEndDisplaying: view!, forRowAt: index)
        return view
    }
    
    func simulateViewNotVisible(at index: Int) {
        let view = feedImageView(at: index)
        let delegate = tableView.delegate
        let indexPath = IndexPath(row: index, section: feedImageSection)
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: indexPath)
    }
    
    func simulateFeedImageViewNearVisible(at index: Int) {
        let indexPath = IndexPath(row: index, section: feedImageSection)
        tableView(tableView, prefetchRowsAt: [indexPath])
    }
    
    func simulateFeedImageViewNotNearVisible(at index: Int) {
        simulateFeedImageViewNearVisible(at: index)
        let indexPath = IndexPath(row: index, section: feedImageSection)
        tableView(tableView, cancelPrefetchingForRowsAt: [indexPath])
    }
    
    func feedImageView(at index: Int) -> UITableViewCell? {
        let indexPath = IndexPath(row: index, section: feedImageSection)
        return tableView(tableView, cellForRowAt: indexPath)
    }
    
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    private var feedImageSection: Int { 0 }
    
    private func swapRefreshControlForIOS17Support() {
        let fakeRefreshControl = IOS17RefreshControlSpy()
        fakeRefreshControl.setupActions(from: refreshControl)
        refreshControl = fakeRefreshControl
    }
    
}

fileprivate class IOS17RefreshControlSpy: UIRefreshControl {
    private var _isRefreshing = false

    override var isRefreshing: Bool { _isRefreshing }
    
    override func beginRefreshing() {
        _isRefreshing = true
    }
    
    override func endRefreshing() {
        _isRefreshing = false
    }
    
    func setupActions(from otherUIRefreshControl: UIRefreshControl?) {
        otherUIRefreshControl?.allTargets.forEach { target in
            otherUIRefreshControl?.actions(
                forTarget: target,
                forControlEvent: .valueChanged
            )?.forEach { action in
                self.addTarget(
                    target,
                    action: Selector(action),
                    for: .valueChanged
                )
            }
        }
    }
}

fileprivate extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
