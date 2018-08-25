//
// NodeList.swift
// Requires: `DataStructures.swift`, `LinkedNodes.swift`
//
// Implements linked lists by using linked node objects and depth counting.
// These implementations are heavier than the most basic linked list can be,
// but they allow conformance to `Collection` and O(1) `count`.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

// MARK: - Linked Lists

/// A depth-counting singly-linked list.
/// Depth-counting allows `Collection` conformance and O(1) `count`.
public final class SinglyLinkedNodeList<DataType: Any>: LinkedNodeList, DepthCounting, MutableCollection, ExpressibleByArrayLiteral {
    public init() { }

    public typealias Element = DataType
    public typealias Node = LinkedNode<Element>
    public typealias Iterator = ForwardLinkIterator<Node>

    public var head: Node?
    public weak var tail: Node?

    public var headDepth: Int = 0
    public var tailDepth: Int = 0
}

extension SinglyLinkedNodeList: Queue, CustomStringConvertible { }

/// A depth-counting doubly-linked list.
/// Depth-counting allows `Collection` conformance and O(1) `count`.
public final class DoublyLinkedList<DataType: Any>: RangeReplaceableNodeList, DepthCounting, ExpressibleByArrayLiteral {
    public required init() { }

    public typealias Element = DataType
    public typealias Node = DoublyLinkedNode<Element>
    public typealias Iterator = ForwardLinkIterator<Node>
    public typealias ReverseIterator = BackwardLinkIterator<Node>

    public var head: Node?
    public weak var tail: Node?

    public var headDepth: Int = 0
    public var tailDepth: Int = 0

    public func makeReverseIterator() -> ReverseIterator {
        return ReverseIterator(tail)
    }
}

extension DoublyLinkedList: Queue, CustomStringConvertible { }

// MARK: - Protocols

// MARK: List Protocols

/// A list composed of linked nodes.
public protocol LinkedNodeList: AppendableList {
    associatedtype Node: ForwardLinked

    /// The first node in the list, or `nil`  if the list is empty.
    var head: Node? { get set }

    /// The last node in the list, or `nil` if the list is empty.
    var tail: Node? { get set }

    /// Removes all nodes from the list.
    mutating func removeAll()

    /// Inserts `node` as the new head of the list.
    mutating func insertAsHead(_ node: Node)

    /// Inserts `node` as the new tail of the list.
    mutating func append(node: Node)

    /// Removes the first node in the list and returns it.
    /// If the list is empty, `nil` is returned. See also `removeFirstNode()`.
    @discardableResult mutating func popFirstNode() -> Node?

    /// Removes the first node in the list and returns it.
    /// The list must not be empty when called. See also `popFirstNode()`.
    @discardableResult mutating func removeFirstNode() -> Node
}

/// A `LinkedList` conforming to this protocol will have the default
/// implementations count depth at both ends of the list. This
/// allows O(1) `count`, and makes it possible to conform to
/// `Collection` as the depths can be used to provide `Comparable`
/// indices.
public protocol DepthCounting: class {
    /// The depth of the list at its head. Inserting to the head
    /// (which should be done with `insertAsHead`) subtracts one
    /// from `headDepth`, while removing from the head increments
    /// it by one. That is, if a list only has front insertions and
    /// removals, `headDepth` will be `-count`.
    ///
    /// Note: Each insertion and removal should be considered only
    /// affecting either head or tail, even if it effectively does
    /// both (e.g., insertion to an empty list, or removal of the
    /// last element).
    ///
    /// The initial value must be 0.
    var headDepth: Int { get set }

    /// The depth of the list at its tail. Appending to the tail
    /// adds one to `tailDepth`, while removing from the tail
    /// decrements it by one. See also `headDepth`.
    ///
    /// The initial value must be 0.
    var tailDepth: Int { get set }
}

/// A bidirectional list implemented as linked nodes.
public protocol BidirectionalNodeList: BidirectionalList, LinkedNodeList { }

/// A range-replaceable node list.
public protocol RangeReplaceableNodeList: BidirectionalNodeList, RangeReplaceableCollection, MutableCollection, BidirectionalCollection { }

// MARK: - List Protocol Extensions

public extension LinkedNodeList {
    /// Is the list empty?
    public var isEmpty: Bool { return head == nil }

    public mutating func insertAsHead(_ node: Node) {
        if let oldHead = head {
            node.linkNext(oldHead)
        } else {
            tail = node // The list was empty
        }
        head = node

        if let depthCounting = self as? DepthCounting {
            depthCounting.headDepth -= 1
        }
    }

    public mutating func append(node: Node) {
        if let oldTail = tail {
            oldTail.linkNext(node)
        } else {
            head = node // The list was empty
        }
        tail = node

        if let depthCounting = self as? DepthCounting {
            depthCounting.tailDepth += 1
        }
    }

    /// Insert `node` after `previousNode`, which must be a node in the list.
    public mutating func insert(node: Node, after previousNode: Node) {
        guard !(previousNode === tail) else {
            append(node: node)
            return
        }

        node.linkNext(previousNode.next)
        previousNode.linkNext(node)

        if let depthCounting = self as? DepthCounting {
            depthCounting.tailDepth += 1
        }
    }

    public mutating func removeAll() {
        tail = nil
        head = nil

        if let depthCounting = self as? DepthCounting {
            depthCounting.headDepth = 0
            depthCounting.tailDepth = 0
        }
    }

    /// Reverse the order of the list.
    public mutating func reverse() {
        var node = head
        var previous: Node? = nil
        while let n = node {
            node = n.next
            n.linkNext(previous)
            previous = n
        }
        let tmp = head
        head = tail
        tail = tmp
    }

    @discardableResult
    public mutating func popFirstNode() -> Node? {
        guard let firstNode = head else { return nil }

        head = firstNode.next
        firstNode.unlinkNext()

        if head == nil {
            tail = nil
        }

        if let depthCounting = self as? DepthCounting {
            depthCounting.headDepth += 1
        }

        return firstNode
    }

    @discardableResult
    public mutating func removeFirstNode() -> Node {
        return popFirstNode()!
    }
}

public extension LinkedNodeList where Node: BackwardLinked {
    /// Inserts `node` before `nextNode`, which must be a node in the list.
    public mutating func insert(node: Node, before nextNode: Node) {
        if let previousNode = nextNode.previous {
            insert(node: node, after: previousNode)
        } else {
            insertAsHead(node)
        }
    }
}

public extension LinkedNodeList where Node: BackwardLinked & DataReference {
    /// Insert `element` before `nextNode`, which must be a node in the list.
    public mutating func insert(_ element: Node.DataType, beforeNode nextNode: Node) {
        self.insert(node: Node(element), before: nextNode)
    }
}

public extension LinkedNodeList where Node: DataReference {
    /// Insert `element` after `previousNode`, which must be a node in the list.
    public mutating func insert(_ element: Node.DataType, afterNode previousNode: Node) {
        self.insert(node: Node(element), after: previousNode)
    }
}

public extension LinkedNodeList where Node: UnlinkableNode, Node: BackwardLinked {
    /// Removes the last node in the list and returns it.
    /// If the list is empty, `nil` is returned. See also `removeLastNode()`.
    @discardableResult
    public mutating func popLastNode() -> Node? {
        guard let lastNode = tail else { return nil }

        tail = lastNode.previous
        lastNode.unlink()

        if tail == nil {
            head = nil
        }

        if let depthCounting = self as? DepthCounting {
            depthCounting.tailDepth -= 1
        }

        return lastNode
    }

    /// Removes the last node in the list and returns it.
    /// The list must not be empty when called. See also `popLastNode()`.
    @discardableResult
    public mutating func removeLastNode() -> Node {
        return popLastNode()!
    }

    /// Removes `node` from the list. The argument must be a node
    /// in this list. Note: existing indices may become invalid
    /// if a node in the middle of the list is removed.
    public mutating func remove(node: Node) {
        if node === head {
            popFirstNode()
            return
        } else if node === tail {
            popLastNode()
            return
        }

        node.unlink()

        if let depthCounting = self as? DepthCounting {
            depthCounting.tailDepth -= 1
        }
    }
}

// MARK: - Data Protocol Extensions

public extension LinkedNodeList where Node: DataReference {
    /// First element in the list, or `nil` if empty.
    public var first: Node.DataType? {
        return head?.data
    }

    /// Last element in the list, or `nil` if empty.
    public var last: Node.DataType? {
        return tail?.data
    }
}

public extension LinkedNodeList where Node: DataReference, Self: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

public extension LinkedNodeList where Node: DataReference {
    /// Make a list with the contents of `array`.
    public init(_ array: [Element]) {
        self.init()
        for element in array {
            append(element)
        }
    }

    /// Insert `element` to the beginning of the list.
    public mutating func insertAsFirst(_ element: Node.DataType) {
        insertAsHead(Node(element))
    }

    /// Append `element` to the end of the list.
    public mutating func append(_ element: Node.DataType) {
        append(node: Node(element))
    }

    /// Removes the first element in the list and returns it.
    /// If the list is empty, `nil` is returned. See also `removeFirst()`.
    @discardableResult
    public mutating func popFirst() -> Node.DataType? {
        return popFirstNode()?.data
    }

    /// Removes the first element in the list and returns it.
    /// The list must not be empty when called. See also `popFirst()`.
    @discardableResult
    public mutating func removeFirst() -> Node.DataType {
        return removeFirstNode().data
    }
}

public extension BidirectionalNodeList where Self.Node: DataReference & BackwardLinked & UnlinkableNode {
    @discardableResult
    public mutating func popLast() -> Node.DataType? {
        return popLastNode()?.data
    }

    @discardableResult
    public mutating func removeLast() -> Node.DataType {
        return removeLastNode().data
    }
}

// MARK: - Sequence Conformance

public extension Sequence where Self: LinkedNodeList, Self.Node: DataReference, Self.Node.DataType == Iterator.Element {
    public func makeIterator() -> ForwardLinkIterator<Node> {
        return ForwardLinkIterator<Node>(head)
    }
}

public extension Sequence where Self: DepthCounting {
    public var underestimatedCount: Int {
        return tailDepth - headDepth
    }
}

// MARK: - Collection Conformance

/// A `Comparable` index type for nodes. The depth is an index generated
/// from adjacent indices, and the `tailDepth` and `headDepth` of a
/// `DepthCounting` list. Note that the `depth` of existing inidices
/// may become invalid if an insertion or removal happens in the middle
/// of the list (but not otherwise).
public struct NodeIndex<Node: AnyObject>: Comparable {
    fileprivate let depth: Int

    private(set) weak var node: Node?

    public static func < (lhs: NodeIndex<Node>, rhs: NodeIndex<Node>) -> Bool {
        return lhs.depth < rhs.depth && !(lhs.node === rhs.node)
    }

    public static func == (lhs: NodeIndex<Node>, rhs: NodeIndex<Node>) -> Bool {
        return lhs.node === rhs.node || lhs.depth == rhs.depth
    }
}

public extension Collection where Self: LinkedNodeList, Self: DepthCounting {
    public typealias DepthIndex = NodeIndex<Node>

    public var startIndex: DepthIndex { return DepthIndex(depth: headDepth, node: head) }

    public var endIndex: DepthIndex { return DepthIndex(depth: tailDepth, node: nil) }

    public func index(after i: DepthIndex) -> DepthIndex {
        return DepthIndex(depth: i.depth + 1, node: i.node?.next)
    }
}

public extension Collection where Self: LinkedNodeList, Self: DepthCounting, Self.Node: DataReference, Self.Node.DataType == Iterator.Element {
    public subscript(index: DepthIndex) -> Node.DataType {
        get {
            return index.node!.data
        }
        set(data) {
            index.node!.data = data
        }
    }

    public var count: Int {
        return tailDepth - headDepth
    }
}

public extension BidirectionalCollection where Self: LinkedNodeList, Self: DepthCounting, Self.Node: BackwardLinked {
    public typealias BidirectionalDepthIndex = NodeIndex<Node>

    public func index(before i: BidirectionalDepthIndex) -> BidirectionalDepthIndex {
        guard let nextNode = i.node else {
            return BidirectionalDepthIndex(depth: tailDepth - 1, node: tail)
        }
        return BidirectionalDepthIndex(depth: i.depth - 1, node: nextNode.previous)
    }
}

public extension RangeReplaceableCollection where Self: LinkedNodeList, Self: DepthCounting, Self.Node: BackwardLinked & UnlinkableNode & DataReference {
    public init<S>(_ elements: S) where S: Sequence, S.Element == Node.DataType {
        self.init()
        append(contentsOf: elements)
    }

    public mutating func append<S>(contentsOf newElements: S) where S: Sequence, S.Element == Node.DataType {
        for element in newElements {
            append(element)
        }
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<NodeIndex<Node>>, with newElements: C) where C: Collection, C.Element == Node.DataType {
        switch (subrange.lowerBound.node, subrange.upperBound.node) {
        case (let lastToRemove, nil) where lastToRemove != nil:
            // range from some node to the end
            while !(popLastNode() === lastToRemove) { }
            fallthrough
        case (nil, nil):
            // the end of the list
            for element in newElements { append(element) }
        case (let firstToRemove, let lastToRemove):
            var insertAfter = firstToRemove?.previous

            var nextNode = firstToRemove ?? head
            while let node = nextNode {
                nextNode = node.next
                remove(node: node)
                if node === lastToRemove { break }
            }

            for element in newElements {
                let newNode = Node(element)
                if let insertionPoint = insertAfter {
                    insert(node: newNode, after: insertionPoint)
                } else {
                    insertAsHead(newNode)
                }
                insertAfter = newNode
            }
        }
    }
}


// These are just to avoid ambiguity with multiple default implementations:

public extension Collection where Self: LinkedNodeList {
    public var isEmpty: Bool { return head == nil }
}

public extension Collection where Self: LinkedNodeList, Self.Node: DataReference, Self.Node.DataType == Self.Iterator.Element {
    public var first: Node.DataType? { return head?.data }
}

public extension BidirectionalCollection where Self: LinkedNodeList, Self.Node: DataReference, Self.Node.DataType == Self.Iterator.Element {
    public var last: Node.DataType? { return tail?.data }
}

public extension RangeReplaceableCollection where Self: LinkedNodeList, Self.Node: DataReference {
    public mutating func append(_ element: Node.DataType) {
        append(node: Node(element))
    }

    @discardableResult
    public mutating func removeFirst() -> Node.DataType {
        return removeFirstNode().data
    }
}

public extension RangeReplaceableNodeList where Self.Node: DataReference & BackwardLinked & UnlinkableNode {
    @discardableResult
    public mutating func popLast() -> Node.DataType? {
        return popLastNode()?.data
    }

    @discardableResult
    public mutating func removeLast() -> Node.DataType {
        return removeLastNode().data
    }
}

// MARK: - CustomStringConvertible

extension LinkedNodeList {
    public var description: String {
        var result = ""
        var nextNode = head
        while let node = nextNode {
            nextNode = node.next
            result = "\(result.isEmpty ? "(" : "\(result),") \(node)"
        }
        return "\(result) )"
    }
}
