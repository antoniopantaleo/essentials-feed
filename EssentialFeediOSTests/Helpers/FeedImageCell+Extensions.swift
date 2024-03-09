//
//  FeedImageCell+Extensions.swift
//  EssentialFeediOSTests
//
//  Created by Antonio Pantaleo on 08/03/24.
//

import UIKit
import EssentialFeediOS

extension FeedImageCell {
    var isShowingLocation: Bool { !locationContainer.isHidden }
    var locationText: String? { locationLabel.text }
    var descriptionText: String? { descriptionLabel.text }
}