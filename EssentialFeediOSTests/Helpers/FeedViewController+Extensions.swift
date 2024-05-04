//
//  FeedViewController+Extensions.swift
//  EssentialFeediOSTests
//
//  Created by Antonio on 04/03/24.
//

import UIKit
@testable import EssentialFeediOS

extension ListViewController {
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }
    
    var numberOfRenderedFeedImageViews: Int {
        tableView(tableView, numberOfRowsInSection: feedImageSection)
    }
    
    var errorMessage: String? {
        errorView?.message
    }
    
    func simulateTapOnErrorView() throws {
        guard errorView?.isHidden == false else { throw NSError(domain: "No view", code: 0) }
        errorView?.gestureRecognizers?.forEach { $0.sendActions() }
    }
    
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            setSmallFrameToPreventRenderingCells()
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
    
    func renderedFeedImageData(at index: Int) -> Data? {
        return simulateViewVisible(at: index)?.renderedImage
    }
    
    private func swapRefreshControlForIOS17Support() {
        let fakeRefreshControl = IOS17RefreshControlSpy()
        fakeRefreshControl.setupActions(from: refreshControl)
        refreshControl = fakeRefreshControl
    }
    
    private func setSmallFrameToPreventRenderingCells() {
        tableView.frame = CGRect(x: 0, y: 0, width: 390, height: 1)
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

fileprivate extension  UIGestureRecognizer {
    
    typealias TargetActionInfo = [(target: AnyObject, action: Selector)]
    
    private func getTargetInfo() -> TargetActionInfo {
        guard let targets = value(forKeyPath: "_targets") as? [NSObject] else {
            return []
        }
        var targetsInfo: TargetActionInfo = []
        for target in targets {
            let description = String(describing: target).trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            var selectorString = description.components(separatedBy: ", ").first ?? ""
            selectorString = selectorString.components(separatedBy: "=").last ?? ""
            let selector = NSSelectorFromString(selectorString)
            
            if let targetActionPairClass = NSClassFromString("UIGestureRecognizerTarget"),
               let targetIvar = class_getInstanceVariable(targetActionPairClass, "_target"),
               let targetObject = object_getIvar(target, targetIvar) {
                targetsInfo.append((target: targetObject as AnyObject, action: selector))
            }
        }
        
        return targetsInfo
    }
    
    func sendActions() {
        let targetsInfo = getTargetInfo()
        for info in targetsInfo {
            info.target.performSelector(onMainThread: info.action, with: self, waitUntilDone: true)
        }
    }
    
}
