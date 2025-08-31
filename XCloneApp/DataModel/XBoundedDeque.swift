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
    public func insertFront(_ element: T) {
        if data.count >= _capacity {
            let k = data.count - _capacity
            for _ in 0...k { popBack() }
        }
        data.insert(element, at: 0)
    }
    
    public func insertBack(_ element: T) {
        if data.count >= _capacity {
            let k = data.count - _capacity
            for _ in 0...k { popFront() }
        }
        data.insert(element, at: data.count)
    }
    
    public func popFront() {
        if !data.isEmpty {
            data.removeFirst()
        }
    }
    
    public func popBack() {
        if !data.isEmpty {
            data.removeLast()
        }
    }
    
}
