//
//  SharedLocalizationTests.swift
//  EssentialFeedTests
//
//  Created by Antonio on 01/05/24.
//

import XCTest
import EssentialFeed

class SharedLocalizationTests: XCTestCase {
    
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Shared"
        let presentationBundle = Bundle(for: LoadResourcePresenter<Any, DummyView>.self)
        let localizationBundles = allLocalizationBundles(in: presentationBundle)
        let localizedStringKeys = allLocalizedStringKeys(in: localizationBundles, table: table)
        
        localizationBundles.forEach { (bundle, localization) in
            localizedStringKeys.forEach { key in
                let localizedString = bundle.localizedString(forKey: key, value: nil, table: table)
                
                if localizedString == key {
                    let language = Locale.current.localizedString(forLanguageCode: localization) ?? ""
                    
                    XCTFail("Missing \(language) (\(localization)) localized string for key: '\(key)' in table: '\(table)'")
                }
            }
        }
    }
    
    private class DummyView: ResourceView {
        func display(_ viewModel: Any) {}
    }
    
}
