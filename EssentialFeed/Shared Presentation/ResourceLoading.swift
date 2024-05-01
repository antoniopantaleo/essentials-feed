//
//  ResourceLoading.swift
//  EssentialFeed
//
//  Created by Antonio on 01/05/24.
//

import Foundation

public struct ResourceLoadingViewModel {
    public let isLoading: Bool
}

public protocol ResourceLoadingView {
    func display(_ viewModel: ResourceLoadingViewModel)
}
