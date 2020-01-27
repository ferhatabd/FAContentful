//
//  ContentServing.swift
//  
//
//  Created by Ferhat Abdullahoglu on 24.12.2019.
//

import Foundation
import Contentful


public protocol ContentServing: class {
    
    /// Asks the delegate for the supported content types
    func contents() -> [Contentful.EntryDecodable.Type]
    
}


public protocol FAContent: Contentful.EntryDecodable, Contentful.FieldKeysQueryable { }
