//
//  Markdown.swift
//  FAContentful
//
//  Created by Ferhat Abdullahoglu on 26.01.2020.
//  Copyright © 2020 Ferhat Abdullahoglu. All rights reserved.
//

import Foundation
import markymark

public struct Markdown {
    
    public static func attributedText(text: String, styling: Styling = styling()) -> NSAttributedString {
        let markyMark = MarkyMark() { $0.setFlavor(ContentfulFlavor()) }
        let markdownItems = markyMark.parseMarkDown(text)
        let config = MarkDownToAttributedStringConverterConfiguration(styling: styling)
        // Configure markymark to leverage the Contentful images API when encountering inline SVGs.
        config.addLayoutBlockBuilder(SVGAttributedStringBlockBuilder())
        
        let converter = MarkDownConverter(configuration: config)
        let attributedText = converter.convert(markdownItems)
        return attributedText
    }
    
    public static func styling(baseFont: UIFont = .systemFont(ofSize: 16.0, weight: .light)) -> Styling {
        let styling = DefaultStyling()
        styling.headingStyling.isBold = true
        styling.paragraphStyling.baseFont = baseFont
        
        // Code blocks.
        styling.codeBlockStyling.baseFont = .sfMonoFont(ofSize: 8.0, weight: .regular)
        styling.codeBlockStyling.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        styling.codeBlockStyling.textColor = .black
        
        return styling
    }
}
