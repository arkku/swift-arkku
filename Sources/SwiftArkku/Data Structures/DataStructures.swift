//
// DataStructures.swift
//
// Defines protocols for general data structures.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

/// A first-in-last-out stack.
public protocol Stack {

    associatedtype Element: Any

    /// Make an empty stack.
    init()

    /// The element on top of the stack.
    var top: Element? { get }

    /// Pushes `element` onto the top of the stack.
    mutating func push(_ element: Element)

    /// Removes the top element from the stack and returns it.
    /// Must not be empty when called!
    @discardableResult mutating func pop() -> Element

    /// Removes the top element from the stack and returns it.
    /// Returns `nil` if the stack is empty.
    mutating func popFirst() -> Element?

    /// Is the stack empty?
    var isEmpty: Bool { get }

}

/// A first-in-first-out queue.
public protocol Queue {

    associatedtype Element: Any

    /// Make an empty queue.
    init()

    /// The element next in line to be dequeued.
    var first: Element? { get }

    /// Adds `element` to the back (tail) of the queue.
    mutating func enqueue(_ element: Element)

    /// Removes the element next in line and returns it.
    /// Must not be empty when called! See also `shift()`.
    mutating func dequeue() -> Element

    /// Removes the element next in line and returns it.
    /// Returns `nil` if the queue is empty. See also `dequeue()`.
    @discardableResult mutating func shift() -> Element?

    /// Is the queue empty?
    var isEmpty: Bool { get }

}

/// A list that can insert to and remove from its head.
public protocol List {
    associatedtype Element

    /// Make an empty list.
    init()

    /// The head of the list.
    var first: Element? { get }

    /// Is the list empty?
    var isEmpty: Bool { get }

    /// Removes the first element from the list and returns it.
    /// Returns `nil` if the list is empty.
    @discardableResult mutating func popFirst() -> Element?

    /// Removes the first element from the list and returns it.
    @discardableResult mutating func removeFirst() -> Element

    /// Inserts `element` into the list as the new `first`.
    mutating func insertAsFirst(_ element: Element)
}

/// A list that provides O(1) operations for accessing the last element
/// and appending to the end of the list. Note that this does not
/// necessarily mean the last element can be removed as O(1), since that
/// would require a backwards link from it: see `BidirectionalList`.
public protocol AppendableList: List {

    /// The tail of the list.
    var last: Element? { get }

    /// Appends `element` to the end of the list as the new `last`.
    mutating func append(_ element: Element)

}

/// A list that can be traversed in both directions.
public protocol BidirectionalList: AppendableList {

    /// Removes the last element from the list and returns it.
    /// Returns `nil` if the list is empty.
    @discardableResult mutating func popLast() -> Element?

    /// Removes the last element from the list and returns it.
    @discardableResult mutating func removeLast() -> Element

}

/// An object with associated data.
public protocol DataReference: class {
    associatedtype DataType: Any

    /// Initialize a reference to `data`.
    init(_ data: DataType)

    /// The referred data.
    var data: DataType { get set }
}

/// An object with associated data, or a sentinel.
public protocol DataOrSentinel: DataReference {

    /// Is this a sentinel? Accessing `data` is not permitted on sentinels.
    var isSentinel: Bool { get }
}

// MARK: - Default Implementations

// Default implementation of `Queue` as a `AppendableList`.
extension Queue where Self: AppendableList {

    public var nextInLine: Self.Element? {
        return first
    }

    public mutating func enqueue(_ element: Self.Element) {
        append(element)
    }

    public mutating func dequeue() -> Self.Element {
        return removeFirst()
    }

    public mutating func shift() -> Self.Element? {
        return popFirst()
    }

}
