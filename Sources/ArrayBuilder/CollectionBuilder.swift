//
//  File.swift
//  coenttb-utils
//
//  Created by Coen ten Thije Boonkkamp on 01/11/2024.
//

import Foundation

@resultBuilder
public struct CollectionBuilder<Element> {
    // MARK: - Core Building Blocks
    
    public static func buildPartialBlock<C: Collection>(first: C) -> C where C.Element == Element {
        first
    }
    
    public static func buildPartialBlock(first: Element) -> [Element] {
        [first]
    }
    
    public static func buildPartialBlock<C: Collection>(accumulated: C, next: Element) -> [Element] where C.Element == Element {
        Array(accumulated) + [next]
    }
    
    public static func buildPartialBlock<C1: Collection, C2: Collection>(accumulated: C1, next: C2) -> [Element]
    where C1.Element == Element, C2.Element == Element {
        Array(accumulated) + Array(next)
    }
    
    // MARK: - Control Flow
    
    public static func buildPartialBlock(first: Void) -> [Element] { [] }
    
    public static func buildPartialBlock(first: Never) -> [Element] {}
    
    public static func buildBlock() -> [Element] { [] }
    
    public static func buildIf<C: RangeReplaceableCollection>(_ element: C?) -> C where C.Element == Element {
        element ?? C()
    }
    
    public static func buildEither<C: Collection>(first: C) -> C where C.Element == Element {
        first
    }
    
    public static func buildEither<C: Collection>(second: C) -> C where C.Element == Element {
        second
    }
    
    public static func buildArray<C: Collection>(_ components: [C]) -> [Element] where C.Element == Element {
        components.flatMap { Array($0) }
    }
}

// Extension for RangeReplaceableCollection types
public extension RangeReplaceableCollection {
    init(@CollectionBuilder<Element> _ builder: () -> [Element]) {
        self.init(builder())
    }
}
