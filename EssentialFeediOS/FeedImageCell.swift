//
//  FeedImageCell.swift
//  EssentialFeediOS
//
//  Created by Antonio Pantaleo on 08/03/24.
//

import UIKit

public final class FeedImageCell: UITableViewCell {
    var onRetry: (() -> Void)?
    
    public let locationContainer = UIView()
    public let locationLabel = UILabel()
    public let descriptionLabel = UILabel()
    public let feedImageContainer = UIView()
    public let feedImageView = UIImageView()
    
    private(set) public lazy var feedImageRetryButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    @objc private func retryButtonTapped() {
        onRetry?()
    }
}
