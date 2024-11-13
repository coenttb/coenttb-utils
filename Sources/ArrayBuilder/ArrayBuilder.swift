import Foundation

@resultBuilder
public struct ArrayBuilder<Element> {
    // MARK: - Core Building Blocks
    
    public static func buildPartialBlock(first: Element) -> [Element] {
        [first]
    }
    
    public static func buildPartialBlock(first: [Element]) -> [Element] {
        first
    }
    
    public static func buildPartialBlock(accumulated: [Element], next: Element) -> [Element] {
        accumulated + [next]
    }
    
    public static func buildPartialBlock(accumulated: [Element], next: [Element]) -> [Element] {
        accumulated + next
    }
    
    // MARK: - Control Flow
    
    public static func buildPartialBlock(first: Void) -> [Element] { [] }
    
    public static func buildPartialBlock(first: Never) -> [Element] {}
    
    public static func buildBlock() -> [Element] { [] }
    
    public static func buildIf(_ element: [Element]?) -> [Element] {
        element ?? []
    }
    
    public static func buildEither(first: [Element]) -> [Element] {
        first
    }
    
    public static func buildEither(second: [Element]) -> [Element] {
        second
    }
    
    public static func buildArray(_ components: [[Element]]) -> [Element] {
        components.flatMap { $0 }
    }
    
    // MARK: - Optional Performance Optimization
    
    // Optional: Capacity hint for better performance with known sizes
    public static func buildFinalResult(_ component: [Element]) -> [Element] {
        component
    }
}

public extension Array {
    init(@ArrayBuilder<Element> _ builder: () -> [Element]) {
        self = builder()
    }
}
