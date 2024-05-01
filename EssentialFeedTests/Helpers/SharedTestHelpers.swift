//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Antonio on 17/09/23.
//

import Foundation
import EssentialFeed

var anyNSError: NSError {
    NSError(domain: "any error", code: 0)
}

var anyURL: URL {
    URL(string: "https://any-url.com")!
}

func makeItem(
    id: UUID,
    description: String? = nil,
    location: String? = nil,
    imageURL: URL
) -> (
    model: FeedImage,
    json: [String: Any]
) {
    let item = FeedImage(
        id: id,
        description: description,
        location: location,
        url: imageURL
    )
    
    let json = [
        "id": id.uuidString,
        "description": description,
        "location": location,
        "image": imageURL.absoluteString
    ].compactMapValues { $0 }
    
    return (item, json)
}

func makeItemsJSON(_ items: [[String: Any]]) -> Data {
    let json = ["items": items]
    return try! JSONSerialization.data(withJSONObject: json)
}

extension Date {
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
    
    func adding(minutes: Int, calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        return calendar.date(byAdding: .minute, value: minutes, to: self)!
    }
    
    func adding(days: Int, calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        calendar.date(byAdding: .day, value: days, to: self)!
    }
}
