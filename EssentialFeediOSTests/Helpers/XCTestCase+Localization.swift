//
//  XCTestCase+Localization.swift
//  EssentialFeediOSTests
//
//  Created by Antonio on 11/03/24.
//

import XCTest

extension XCTestCase {
    
    func localized(bundle: Bundle, table: String = "Feed", _ key: String, file: StaticString = #file, line: UInt = #line) -> String {
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }
        return value
    }
}
