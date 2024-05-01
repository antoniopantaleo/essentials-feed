//
//  FeedImageViewModel.swift
//  EssentialFeediOS
//
//  Created by Antonio on 11/03/24.
//
import Foundation

public struct FeedImageViewModel {
    public let description: String?
    public let location: String?
    
    public var hasLocation: Bool {
        return location != nil
    }
}


public enum FeedImagePresenter {
    
    public static func map(_ image: FeedImage) -> FeedImageViewModel{
        FeedImageViewModel(
            description: image.description,
            location: image.location
        )
    }
}
