//
//  XBoundedDeque.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/30/25.
//

/**
 * A simple array-based bounded deque implementation that can be used
 * to implement a sliding window or "buffer"
 */
public class XBoundedDeque<T: Any> {
    
    private let _capacity: Int
    private var data: [T] = []
    
    subscript(index: Int) -> T {
        return data[index]
    }
    
    // MARK: Public Properties
    public var front: T? {
        return data.first
    }
    
    public var back: T? {
        return data.last
    }
    
    public var count: Int {
        return data.count
    }
    
    public var isEmpty: Bool {
        return data.isEmpty
    }
    
    public var capacity: Int {
        return _capacity
    }
    
    // MARK: Public Init
    public init(_ capacity: Int) {
        _capacity = capacity
    }
    
    public init(_ elements: [T], _ capacity: Int) {
        data = elements
        _capacity = capacity
    }
    
    // MARK: Public API
    public func insertFront(_ element: T) -> [T] {
        var removedElements: [T] = []
        if data.count >= _capacity {
            let k = data.count - _capacity
            for _ in 0...k {
                if let poppedElement = popBack() {
                    removedElements.append(poppedElement)
                }
            }
        }
        data.insert(element, at: 0)
        return removedElements
    }
    
    public func insertBack(_ element: T) -> [T] {
        var removedElements: [T] = []
        if data.count >= _capacity {
            let k = data.count - _capacity
            for _ in 0...k {
                if let poppedElement = popFront() {
                    removedElements.append(poppedElement)
                }
            }
        }
        data.insert(element, at: data.count)
        return removedElements
    }
    
    public func popFront() -> T? {
        if !data.isEmpty {
            return data.removeFirst()
        }
        return nil
    }
    
    public func popBack() -> T? {
        if !data.isEmpty {
            return data.removeLast()
        }
        return nil
    }
    
    public func removeAll() {
        data.removeAll()
    }
    
}
