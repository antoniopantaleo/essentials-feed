//
//  ResourceError.swift
//  EssentialFeed
//
//  Created by Antonio on 01/05/24.
//

import Foundation

public struct ResourceErrorViewModel {
    public let message: String?
    
    static var noError: ResourceErrorViewModel {
        return ResourceErrorViewModel(message: nil)
    }
    
    static func error(message: String) -> ResourceErrorViewModel {
        return ResourceErrorViewModel(message: message)
    }
}

public protocol ResourceErrorView {
    func display(_ viewModel: ResourceErrorViewModel)
}
