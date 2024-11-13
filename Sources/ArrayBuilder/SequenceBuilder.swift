//
//  File.swift
//  coenttb-utils
//
//  Created by Coen ten Thije Boonkkamp on 01/11/2024.
//

import Foundation

@resultBuilder
public struct SequenceBuilder<Element> {
    // MARK: - Core Building Blocks
    
    public static func buildPartialBlock<S: Sequence>(first: S) -> [Element] where S.Element == Element {
        Array(first)
    }
    
    public static func buildPartialBlock(first: Element) -> [Element] {
        [first]
    }
    
    public static func buildPartialBlock<S: Sequence>(accumulated: [Element], next: S) -> [Element] where S.Element == Element {
        accumulated + Array(next)
    }
    
    public static func buildPartialBlock(accumulated: [Element], next: Element) -> [Element] {
        accumulated + [next]
    }
    
    // MARK: - Control Flow
    
    public static func buildPartialBlock(first: Void) -> [Element] { [] }
    
    public static func buildPartialBlock(first: Never) -> [Element] {}
    
    public static func buildBlock() -> [Element] { [] }
    
    public static func buildIf<S: Sequence>(_ element: S?) -> [Element] where S.Element == Element {
        element.map { Array($0) } ?? []
    }
    
    public static func buildEither<S: Sequence>(first: S) -> [Element] where S.Element == Element {
        Array(first)
    }
    
    public static func buildEither<S: Sequence>(second: S) -> [Element] where S.Element == Element {
        Array(second)
    }
    
    public static func buildArray<S: Sequence>(_ components: [S]) -> [Element] where S.Element == Element {
        components.flatMap { Array($0) }
    }
}


