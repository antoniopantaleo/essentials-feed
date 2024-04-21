//
//  RemoteImageCommentsLoader.swift
//  EssentialFeed
//
//  Created by Antonio Pantaleo on 16/03/24.
//

import Foundation

public typealias RemoteImageCommentsLoader = RemoteLoader<[ImageComment]>
public extension RemoteImageCommentsLoader {
    
    convenience init(url: URL, client: HTTPClient) {
        self.init(
            url: url,
            client: client,
            mapper: ImageCommentsMapper.map
        )
    }
}
