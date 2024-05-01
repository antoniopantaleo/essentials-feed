//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Antonio on 17/09/23.
//

import Foundation
import EssentialFeed

extension Date {
    private var feedCacheMaxAgeInDays: Int { 7 }
    
    func minusFeedCacheMaxAge() -> Date {
        adding(days: -feedCacheMaxAgeInDays)
    }
    
}

func uniqueImage() -> FeedImage {
    FeedImage(
        id: UUID(),
        description: "any description",
        location: "any location",
        url: anyURL
    )
}

func uniqueImageFeed() -> (items: [FeedImage], localFeedItems: [LocalFeedImage]) {
    let items = [uniqueImage(), uniqueImage()]
    let localFeedItems = items.map {
        LocalFeedImage(
            id: $0.id,
            description: $0.description,
            location: $0.location,
            url: $0.url
        )
    }
    return (items, localFeedItems)
}
