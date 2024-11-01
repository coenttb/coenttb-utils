//
//  File.swift
//  coenttb-utils
//
//  Created by Coen ten Thije Boonkkamp on 01/11/2024.
//

import Foundation


@resultBuilder
public struct ArrayBuilder<Element> {
    // Basic building block - single element
    public static func buildExpression(_ element: Element) -> [Element] {
        [element]
    }
    
    // Basic building block - array
    public static func buildExpression(_ elements: [Element]) -> [Element] {
        elements
    }
    
    // Combine arrays from multiple statements
    public static func buildBlock(_ components: [Element]...) -> [Element] {
        components.flatMap { $0 }
    }
    
    // Handle if statement without else
    public static func buildOptional(_ component: [Element]?) -> [Element] {
        component ?? []
    }
    
    // Handle if/else statements
    public static func buildEither(first component: [Element]) -> [Element] {
        component
    }
    
    public static func buildEither(second component: [Element]) -> [Element] {
        component
    }
    
    // Handle availability conditions
    public static func buildLimitedAvailability(_ component: [Element]) -> [Element] {
        component
    }
    
    // Handle for/foreach loops
    public static func buildArray(_ components: [[Element]]) -> [Element] {
        components.flatMap { $0 }
    }
    
    // Final result transformation if needed
    public static func buildFinalResult(_ component: [Element]) -> [Element] {
        component
    }
}

