//
//  FeedImageCell.swift
//  EssentialFeediOS
//
//  Created by Antonio Pantaleo on 08/03/24.
//

import UIKit

public final class FeedImageCell: UITableViewCell {
    var onRetry: (() -> Void)?
    
    @IBOutlet private(set) weak var locationContainer: UIView!
    @IBOutlet private(set) weak var locationLabel: UILabel!
    @IBOutlet private(set) weak var descriptionLabel: UILabel!
    @IBOutlet private(set) weak var feedImageContainer: UIView!
    @IBOutlet private(set) weak var feedImageView: UIImageView!
    @IBOutlet private(set) weak var feedImageRetryButton: UIButton!
    
    @IBAction private func retryButtonTapped() {
        onRetry?()
    }
}
