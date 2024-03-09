//
//  FeedViewController+Extensions.swift
//  EssentialFeediOSTests
//
//  Created by Antonio on 04/03/24.
//

import UIKit
import EssentialFeediOS

extension FeedViewController {
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }
    
    var numberOfRenderedFeedImageViews: Int {
        tableView(tableView, numberOfRowsInSection: feedImageSection)
    }
    
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            swapRefreshControlForIOS17Support()
            beginAppearanceTransition(true, animated: false)
            endAppearanceTransition()
        }
    }
    
    func simulateViewVisible(at index: Int) {
        _ = feedImageView(at: index)
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
        let newRefreshControl = IOS17RefreshControlSpy()
        newRefreshControl.setupActions(from: refreshControl)
        refreshControl = newRefreshControl
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
