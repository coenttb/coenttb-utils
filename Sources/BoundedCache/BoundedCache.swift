//
//  File.swift
//  coenttb-web
//
//  Created by Coen ten Thije Boonkkamp on 19/12/2024.
//

import Foundation

/// A dictionary-like structure with a maximum capacity that evicts oldest entries when full
public struct BoundedCache<Key: Hashable, Value> {
    private var storage: [Key: Value] = [:]
    private var accessOrder: [Key] = []
    private let capacity: Int
    
    public init(capacity: Int) {
        self.capacity = max(1, capacity)
    }
    
    public mutating func insert(_ value: Value, forKey key: Key) {
        if storage[key] != nil {
            storage[key] = value
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
                accessOrder.append(key)
            }
            return
        }
        
        if storage.count >= capacity {
            if let oldestKey = accessOrder.first {
                storage.removeValue(forKey: oldestKey)
                accessOrder.removeFirst()
            }
        }
        
        storage[key] = value
        accessOrder.append(key)
    }
    
    public mutating func removeValue(forKey key: Key) -> Value? {
        guard let value = storage.removeValue(forKey: key) else { return nil }
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
        return value
    }
    
    public func getValue(forKey key: Key) -> Value? {
        storage[key]
    }
    
    public var count: Int {
        storage.count
    }
    
    public mutating func removeAll() {
        storage.removeAll()
        accessOrder.removeAll()
    }
    
    public mutating func filter(_ isIncluded: (Key, Value) throws -> Bool) rethrows {
        var newStorage: [Key: Value] = [:]
        var newOrder: [Key] = []
        
        try accessOrder.forEach { key in
            if let value = storage[key],
               try isIncluded(key, value) {
                newStorage[key] = value
                newOrder.append(key)
            }
        }
        
        storage = newStorage
        accessOrder = newOrder
    }
}
