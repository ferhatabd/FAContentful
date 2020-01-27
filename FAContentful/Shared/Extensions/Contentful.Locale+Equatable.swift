//
//  File.swift
//  
//
//  Created by Ferhat Abdullahoglu on 25.12.2019.
//

import Foundation
import Contentful

extension Contentful.Locale: Equatable {}

public func ==(lhs: Contentful.Locale, rhs: Contentful.Locale) -> Bool {
    return lhs.code == rhs.code && lhs.name == rhs.name && lhs.fallbackLocaleCode == rhs.fallbackLocaleCode && lhs.isDefault == rhs.isDefault
}


public extension Contentful.Locale {
    
    /// The default locale of this application and of the associated space in Contentful.
    static func americanEnglish() -> Contentful.Locale {
        let jsonData = """
        {
            "code": "en-US",
            "default": true,
            "name": "English (United States)",
            "fallbackCode": null
        }
        """.data(using: .utf8)!
        
        let locale = try! JSONDecoder().decode(Contentful.Locale.self, from: jsonData)
        return locale
    }
    
    static func german() -> Contentful.Locale {
        let jsonData = """
        {
            "code": "de-DE",
            "default": false,
            "name": "German (Germany)",
            "fallbackCode": "en-US"
        }
        """.data(using: .utf8)!
        
        let locale = try! JSONDecoder().decode(Contentful.Locale.self, from: jsonData)
        return locale
    }
    
    static func turkish() -> Contentful.Locale {
        let jsonData = """
        {
            "code": "tr-TR",
            "default": false,
            "name": "Turkish (Turkey)",
            "fallbackCode": "en-US"
        }
        """.data(using: .utf8)!
        
        let locale = try! JSONDecoder().decode(Contentful.Locale.self, from: jsonData)
        return locale
    }
    
}

