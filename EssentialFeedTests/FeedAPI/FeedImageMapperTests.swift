//
//  FeedImageMapperTests.swift
//  EssentialFeedTests
//
//  Created by Antonio Pantaleo on 21/04/24.
//

import Foundation

import XCTest
import EssentialFeed

class FeedImageMapperTests: XCTestCase {

    func test_map_throwsErrorOnNon200HTTPResponse() throws {
        let samples = [199, 301, 300, 400, 500]
        let anyData = Data("any data".utf8)

        try samples.forEach { code in
            XCTAssertThrowsError(
                try FeedImageMapper.map(
                    anyData,
                    from: HTTPURLResponse(
                        url: anyURL,
                        statusCode: code,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                )
            )
        }
    }

    func test_map_deliversInvalidDataErrorOn200HTTPResponseWithEmptyData() {
        let emptyData = Data()

        XCTAssertThrowsError(
            try FeedImageMapper.map(
                emptyData,
                from: HTTPURLResponse(
                    url: anyURL,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
            )
        )
    }

    func test_map_deliversReceivedNonEmptyDataOn200HTTPResponse() throws {
        let nonEmptyData = Data("non-empty data".utf8)

        let result = try FeedImageMapper.map(
            nonEmptyData,
            from: HTTPURLResponse(
                url: anyURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        )

        XCTAssertEqual(result, nonEmptyData)
    }

}
