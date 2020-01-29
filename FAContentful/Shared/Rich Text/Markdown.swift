//
//  Markdown.swift
//  FAContentful
//
//  Created by Ferhat Abdullahoglu on 26.01.2020.
//  Copyright © 2020 Ferhat Abdullahoglu. All rights reserved.
//

import Foundation
#if canImport(markymark)
import markymark
#elseif canImport(markymark_tvOS)
import markymark_tvOS
#endif



public struct Markdown {
    
    public static func attributedText(text: String, styling: Styling = styling()) -> NSAttributedString {
        let markyMark = MarkyMark() { $0.setFlavor(ContentfulFlavor()) }
        let markdownItems = markyMark.parseMarkDown(text)
        let config = MarkDownToAttributedStringConverterConfiguration(styling: styling)
        
        #if os(iOS)
        // Configure markymark to leverage the Contentful images API when encountering inline SVGs.
        config.addLayoutBlockBuilder(SVGAttributedStringBlockBuilder())
        #endif
        let converter = MarkDownConverter(configuration: config)
        let attributedText = converter.convert(markdownItems)
        return attributedText
    }
    
    public static func styling(baseFont: UIFont = .systemFont(ofSize: 16.0, weight: .light)) -> Styling {
        let styling = DefaultStyling()
        styling.headingStyling.isBold = true
        styling.boldStyling.isBold = true
        styling.paragraphStyling.baseFont = baseFont
        styling.boldStyling.baseFont = .systemFont(ofSize: 16, weight: .bold)
        
        return styling
    }
}
