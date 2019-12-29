//
//  File.swift
//  
//
//  Created by Ferhat Abdullahoglu on 25.12.2019.
//

import Foundation

extension ContentfulService.State.API: Equatable {
    static public func ==(lhs: ContentfulService.State.API, rhs: ContentfulService.State.API) -> Bool {
        switch (lhs, rhs) {
        case (.delivery, .delivery):    return true
        case (.preview, .preview):      return true
        default:                        return false
        }
    }
}
