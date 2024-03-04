//
//  FeedViewController+Extensions.swift
//  EssentialFeediOSTests
//
//  Created by Antonio on 04/03/24.
//

import Foundation
import UIKit

extension FeedViewController {
    
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            swapRefreshControlForIOS17Support()
            beginAppearanceTransition(true, animated: false)
            endAppearanceTransition()
        }
    }
    
    func simulatePullToRefresh() {
        refreshControl?.simulatePullToRefresh()
    }
    
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
