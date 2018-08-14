//
// LinkedList.swift
// Requires: `DataStructures.swift`
//
// Implements a very simple linked list.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

/// A singly-linked list with a very simple implementation.
public enum LinkedList<ElementType>: List, Sequence, ExpressibleByArrayLiteral, Stack {
    public typealias Element = ElementType

    case empty
    indirect case node(element: Element, tail: LinkedList<Element>)

    public init() {
        self = .empty
    }

    /// Make a linked list with the contents of `array`.
    public init(_ array: [Element]) {
        self.init()
        for element in array.reversed() {
            self = .node(element: element, tail: self)
        }
    }

    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }

    public var first: Element? {
        switch self {
        case .empty:
            return nil
        case .node(element: let element, tail: _):
            return element
        }
    }

    public var isEmpty: Bool {
        switch self {
        case .empty: return true
        default: return false
        }
    }

    public mutating func popFirst() -> Element? {
        switch self {
        case .empty:
            return nil
        case .node(element: let element, tail: let tail):
            self = tail
            return element
        }
    }

    public mutating func removeFirst() -> Element {
        switch self {
        case .empty:
            assert(false, "cannot be called on an empty list")
        case .node(element: let element, tail: let tail):
            self = tail
            return element
        }
    }

    public mutating func insertAsFirst(_ element: Element) {
        self = .node(element: element, tail: self)
    }

    /// Make the list empty.
    public mutating func removeAll() {
        self = .empty
    }

    public func makeIterator() -> Iterator {
        return Iterator(self)
    }

    public struct Iterator: IteratorProtocol, Sequence {
        public typealias Element = ElementType

        public init(_ linkedList: LinkedList<Element>) {
            position = linkedList
        }

        private var position: LinkedList<Element>

        public mutating func next() -> ElementType? {
            switch position {
            case .empty:
                return nil
            case .node(element: let element, tail: let tail):
                position = tail
                return element
            }
        }
    }

}

// MARK: - Equatable

extension LinkedList: Equatable where Element: Equatable {
    public static func == (lhs: LinkedList<Element>, rhs: LinkedList<Element>) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case (.empty, _), (_, .empty):
            return false
        case (.node(element: let e1, tail: let tail1), .node(element: let e2, tail: let tail2)):
            return e1 == e2 && tail1 == tail2
        }
    }
}

// MARK: - Comparable

extension LinkedList: Comparable where Element: Comparable {
    public static func < (lhs: LinkedList<Element>, rhs: LinkedList<Element>) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return false
        case (.empty, _):
            return true
        case (_, .empty):
            return false
        case (.node(element: let e1, tail: let tail1), .node(element: let e2, tail: let tail2)):
            if e1 == e2 {
                return tail1 < tail2
            } else if e1 < e2 {
                return true
            } else {
                return false
            }
        }
    }
}

// MARK: - Custom String Convertible

extension LinkedList: CustomStringConvertible {
    public var description: String {
        var result = ""
        for element in self {
            result = "\(result.isEmpty ? "(" : "\(result),") \(element)"
        }
        return "\(result) )"
    }
}

extension LinkedList: CustomDebugStringConvertible where Element: CustomDebugStringConvertible {
    public var debugDescription: String {
        var result = "LinkedList("
        for element in self {
            result = "\(result) \(element.debugDescription) ->"
        }
        return "\(result) . )"
    }
}
