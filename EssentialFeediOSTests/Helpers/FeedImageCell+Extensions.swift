//
//  FeedImageCell+Extensions.swift
//  EssentialFeediOSTests
//
//  Created by Antonio Pantaleo on 08/03/24.
//

import UIKit
@testable import EssentialFeediOS

extension FeedImageCell {
    var isShowingLocation: Bool { !locationContainer.isHidden }
    var isShowingImageLoadingIndicator: Bool { feedImageContainer.isShimmering }
    var locationText: String? { locationLabel.text }
    var descriptionText: String? { descriptionLabel.text }
    var renderedImage: Data? { feedImageView.image?.pngData() }
    var isShowingRetryAction: Bool { !feedImageRetryButton.isHidden }
    func simulateRetryAction() { feedImageRetryButton.simulateTap() }
}
