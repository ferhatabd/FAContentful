//
//  File.swift
//  
//
//  Created by Ferhat Abdullahoglu on 25.12.2019.
//

import Foundation
import Contentful

public class Module: Resource, StatefulResource {

    public let sys: Sys

    public init(sys: Sys) {
        self.sys = sys
    }
    
    public var state = ResourceState.upToDate
}
