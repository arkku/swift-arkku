//
// ArrayExtensions.swift
// Requires: `DataStructures.swift`
//
// Extends `Array` to conform to `Stack`, `Queue`, and `BidirectionalList`.
// Note that some of the operations are O(n).
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

extension Array: BidirectionalList {
    /// Insert `element` as `first`.
    ///
    /// Note that this is O(n) when implemented as an array.
    public mutating func insertAsFirst(_ element: Element) {
        insert(element, at: startIndex)
    }
}

extension Array: Stack {
    public var top: Element? {
        return last
    }

    public mutating func push(_ element: Element) {
        append(element)
    }

    public mutating func pop() -> Element {
        return removeLast()
    }

    public mutating func popFirst() -> Element? {
        guard !isEmpty else { return nil }
        return removeLast()
    }
}

// Note: `dequeue` and `shift` are O(n) when implemented on `Array`.
extension Array: Queue {
    public mutating func enqueue(_ element: Element) {
        append(element)
    }

    /// Remove and return the first element in the queue.
    /// Must not be called on an empty array!
    ///
    /// Note that this is O(n) when implemented as an array.
    public mutating func dequeue() -> Element {
        return removeFirst()
    }

    /// Remove and return the first element in the queue, or
    /// `nil` if the queue is empty.
    ///
    /// Note that this is O(n) when implemented as an array.
    public mutating func shift() -> Element? {
        guard !isEmpty else { return nil }
        return removeFirst()
    }
}
