//
//  FeedImageDataMapper.swift
//  EssentialFeed
//
//  Created by Antonio Pantaleo on 21/04/24.
//

import Foundation

public final class FeedImageMapper {
    public enum Error: Swift.Error {
        case invalidData
    }

    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> Data {
        guard isOK(response), !data.isEmpty else {
            throw Error.invalidData
        }

        return data
    }
    
    private static func isOK(_ response: HTTPURLResponse) -> Bool {
        (200...299).contains(response.statusCode)
    }
}
