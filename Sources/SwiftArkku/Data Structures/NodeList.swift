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

// MARK: - Doubly-Linked List

/// A depth-counting doubly-linked list.
///
/// Note that even though technically possible, one must not modify the list
/// by linking or unlinking nodes manually. Doing so will break depth-counting
/// as well as the `head` and `tail` links. Instead use the collection's
/// methods to insert, append, and/or remove nodes.
///
/// Depth-counting allows conformance to `RangeReplaceableCollection` as well
/// as O(1) `count`.
public final class DoublyLinkedList<DataType: Any>: RangeReplaceableNodeList, DepthCounting, Queue, CustomStringConvertible, ExpressibleByArrayLiteral {
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

    public var description: String {
        var result = ""
        var nextNode = head
        while let node = nextNode {
            nextNode = node.next
            result = "\(result.isEmpty ? "(" : "\(result),") \(node)"
        }
        return "\(result.isEmpty ? "(" : result) )"
    }
}

/// A depth-counting doubly-linked list of nodes.
///
/// This implementation uses sentinel nodes at the head and tail of the list,
/// which makes the implementation simpler and generally faster, but it means
/// that it is not possible to manually iterate through the `next` and
/// `previous` links of nodes without checking `isSentinel`. Attempting to
/// access the `data` of a sentinel node crashes the program!
///
/// Note that even though technically possible, one should not modify the list
/// by linking or unlinking nodes manually. Doing so will break depth-counting.
/// Instead use the collection's methods to insert, append, and/or remove nodes.
///
/// Depth-counting allows conformance to `RangeReplaceableCollection` as well
/// as O(1) `count`.
public final class NodeList<DataType: Any>: SentinelNodeList, RangeReplaceableNodeList, DepthCounting, Queue, CustomStringConvertible, ExpressibleByArrayLiteral {
    public typealias Element = DataType
    public typealias Node = NodeOrSentinel<Element>

    public init() {
        headSentinel.linkNext(tailSentinel)
    }

    public let headSentinel = Node()
    public let tailSentinel = Node()

    public var headDepth: Int = 0
    public var tailDepth: Int = 0

    public var description: String {
        var result = ""
        for element in self {
            result = "\(result.isEmpty ? "(" : "\(result),") \(element)"
        }
        return "\(result.isEmpty ? "(" : result) )"
    }

    public func reverse() {
        var node: Node? = headSentinel
        var previous: Node? = nil
        while let n = node {
            node = n.next
            n.linkNext(previous)
            previous = n
        }
        headSentinel.previous?.linkNext(tailSentinel)
        headSentinel.linkNext(tailSentinel.next)
        tailSentinel.next = nil
        headSentinel.previous = nil
    }
}

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

/// A linked list of nodes where two sentinel nodes are used to simplify the
/// implementation; these permanent nodes at the ends of the list do not
/// carry data and must never be removed.
public protocol SentinelNodeList: LinkedNodeList where Node: DataOrSentinelNode {
    var headSentinel: Node { get }
    var tailSentinel: Node { get }
}

// MARK: - List Protocol Extensions

public extension SentinelNodeList where Self: DepthCounting {
    var head: Node? {
        get {
            if let headNode = headSentinel.next, !headNode.isSentinel {
                return headNode
            }
            return nil
        }
        set {
            if let newHead = newValue {
                let oldHead = headSentinel.next
                if !(oldHead === newHead) {
                    newHead.linkNext(oldHead)
                }
                headSentinel.linkNext(newHead)
            } else {
                removeAll()
            }
        }
    }

    weak var tail: Node? {
        get {
            if let tailNode = tailSentinel.previous, !tailNode.isSentinel {
                return tailNode
            }
            return nil
        }
        set {
            if let newTail = newValue {
                let oldTail = tailSentinel.previous!
                if !(oldTail === newTail) {
                    oldTail.linkNext(newTail)
                }
                newTail.linkNext(tailSentinel)
            } else {
                removeAll()
            }
        }
    }

    typealias Iterator = SentinelForwardIterator<Node>
    typealias ReverseIterator = SentinelReverseIterator<Node>

    func makeIterator() -> Iterator {
        return Iterator(position: headSentinel.next)
    }

    func makeReverseIterator() -> ReverseIterator {
        return ReverseIterator(position: tailSentinel.previous)
    }

    mutating func insertAsHead(_ node: Node) {
        assert(!node.isSentinel)
        node.linkAfter(headSentinel)
        headDepth -= 1
    }

    mutating func append(node: Node) {
        assert(!node.isSentinel)
        node.linkBefore(tailSentinel)
        tailDepth += 1
    }

    mutating func insert(node: Node, after previousNode: Node) {
        assert(!(previousNode === tailSentinel))
        node.linkAfter(previousNode)
        tailDepth += 1
    }

    mutating func insert(node: Node, before nextNode: Node) {
        assert(!(nextNode === headSentinel))
        node.linkBefore(nextNode)
        headDepth -= 1
    }

    mutating func remove(node: Node) {
        assert(!node.isSentinel)
        node.unlink()
        tailDepth -= 1
    }

    @discardableResult
    mutating func popFirstNode() -> Node? {
        guard let firstNode = headSentinel.next, !firstNode.isSentinel else { return nil }
        firstNode.unlink()
        headDepth += 1
        return firstNode
    }

    // FIXME: Currently the compiler is choosing another implementation instead of this
    @discardableResult
    mutating func popLastNode() -> Node? {
        guard let lastNode = tailSentinel.previous, !lastNode.isSentinel else { return nil }
        lastNode.unlink()
        tailDepth -= 1
        return lastNode
    }

    mutating func removeAll() {
        headSentinel.linkNext(tailSentinel)
        headDepth = 0
        tailDepth = 0
    }
}

public extension LinkedNodeList {
    /// Is the list empty?
    var isEmpty: Bool { return head == nil }

    mutating func insertAsHead(_ node: Node) {
        node.linkNext(head)
        head = node
        if tail == nil {
            tail = node // The list was empty
        }

        if let depthCounting = self as? DepthCounting {
            depthCounting.headDepth -= 1
        }
    }

    mutating func append(node: Node) {
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
    mutating func insert(node: Node, after previousNode: Node) {
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

    mutating func removeAll() {
        tail = nil
        head = nil

        if let depthCounting = self as? DepthCounting {
            depthCounting.headDepth = 0
            depthCounting.tailDepth = 0
        }
    }

    @discardableResult
    mutating func popFirstNode() -> Node? {
        guard let oldHead = head else { return nil }

        if let newHead = oldHead.next {
            if let oldHead = oldHead as? UnlinkableNode {
                oldHead.unlink()
            } else {
                oldHead.next = nil
            }
            head = newHead
        } else {
            head = nil
            tail = nil
        }

        if let depthCounting = self as? DepthCounting {
            depthCounting.headDepth += 1
        }

        return oldHead
    }

    @discardableResult
    mutating func removeFirstNode() -> Node {
        return popFirstNode()!
    }
}

public extension LinkedNodeList where Node: BackwardLinked {
    /// Inserts `node` before `nextNode`, which must be a node in the list.
    mutating func insert(node: Node, before nextNode: Node) {
        if let previousNode = nextNode.previous {
            insert(node: node, after: previousNode)
        } else {
            insertAsHead(node)
        }
    }
}

public extension LinkedNodeList where Node: BackwardLinked & DataReference {
    /// Insert `element` before `nextNode`, which must be a node in the list.
    mutating func insert(_ element: Node.DataType, beforeNode nextNode: Node) {
        self.insert(node: Node(element), before: nextNode)
    }
}

public extension LinkedNodeList where Node: DataReference {
    /// Insert `element` after `previousNode`, which must be a node in the list.
    mutating func insert(_ element: Node.DataType, afterNode previousNode: Node) {
        self.insert(node: Node(element), after: previousNode)
    }
}

public extension LinkedNodeList where Node: UnlinkableNode & BackwardLinked {
    /// Removes the last node in the list and returns it.
    /// If the list is empty, `nil` is returned. See also `removeLastNode()`.
    @discardableResult
    mutating func popLastNode() -> Node? {
        guard let oldTail = tail else { return nil }

        if let newTail = oldTail.previous {
            oldTail.unlink()
            tail = newTail
        } else {
            head = nil
            tail = nil
        }

        if let depthCounting = self as? DepthCounting {
            depthCounting.tailDepth -= 1
        }

        return oldTail
    }
}

public extension LinkedNodeList where Node: UnlinkableNode & BackwardLinked {
    /// Removes the last node in the list and returns it.
    /// The list must not be empty when called. See also `popLastNode()`.
    @discardableResult
    mutating func removeLastNode() -> Node {
        return popLastNode()!
    }

    /// Removes `node` from the list. The argument must be a node
    /// in this list. Note: existing indices may become invalid
    /// if a node in the middle of the list is removed.
    mutating func remove(node: Node) {
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
    var first: Node.DataType? {
        return head?.data
    }

    /// Last element in the list, or `nil` if empty.
    var last: Node.DataType? {
        return tail?.data
    }
}

public extension LinkedNodeList where Node: DataReference, Self: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

public extension LinkedNodeList where Node: DataReference {
    /// Make a list with the contents of `array`.
    init(_ array: [Element]) {
        self.init()
        for element in array {
            append(element)
        }
    }

    /// Insert `element` to the beginning of the list.
    mutating func insertAsFirst(_ element: Node.DataType) {
        insertAsHead(Node(element))
    }

    /// Append `element` to the end of the list.
    mutating func append(_ element: Node.DataType) {
        append(node: Node(element))
    }

    /// Removes the first element in the list and returns it.
    /// If the list is empty, `nil` is returned. See also `removeFirst()`.
    @discardableResult
    mutating func popFirst() -> Node.DataType? {
        return popFirstNode()?.data
    }

    /// Removes the first element in the list and returns it.
    /// The list must not be empty when called. See also `popFirst()`.
    @discardableResult
    mutating func removeFirst() -> Node.DataType {
        return removeFirstNode().data
    }
}

public extension BidirectionalNodeList where Self.Node: DataReference & BackwardLinked & UnlinkableNode {
    @discardableResult
    mutating func popLast() -> Node.DataType? {
        return popLastNode()?.data
    }

    @discardableResult
    mutating func removeLast() -> Node.DataType {
        return removeLastNode().data
    }
}

// MARK: - Sequence Conformance

public extension Sequence where Self: LinkedNodeList, Self.Node: DataReference, Self.Node.DataType == Iterator.Element {
    func makeIterator() -> ForwardLinkIterator<Node> {
        return ForwardLinkIterator<Node>(head)
    }
}

public extension Sequence where Self: DepthCounting {
    var underestimatedCount: Int {
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
    typealias DepthIndex = NodeIndex<Node>

    var startIndex: DepthIndex { return DepthIndex(depth: headDepth, node: head) }

    var endIndex: DepthIndex { return DepthIndex(depth: tailDepth, node: nil) }

    func index(after i: DepthIndex) -> DepthIndex {
        return DepthIndex(depth: i.depth + 1, node: i.node?.next)
    }
}

public extension Collection where Self: LinkedNodeList, Self: DepthCounting, Self.Node: DataReference, Self.Node.DataType == Iterator.Element {
    subscript(index: DepthIndex) -> Node.DataType {
        get {
            return index.node!.data
        }
        set(data) {
            index.node!.data = data
        }
    }

    var count: Int {
        return tailDepth - headDepth
    }
}

public extension BidirectionalCollection where Self: LinkedNodeList, Self: DepthCounting, Self.Node: BackwardLinked {
    typealias BidirectionalDepthIndex = NodeIndex<Node>

    func index(before i: BidirectionalDepthIndex) -> BidirectionalDepthIndex {
        guard let nextNode = i.node else {
            return BidirectionalDepthIndex(depth: tailDepth - 1, node: tail)
        }
        return BidirectionalDepthIndex(depth: i.depth - 1, node: nextNode.previous)
    }
}

public extension RangeReplaceableCollection where Self: LinkedNodeList, Self: DepthCounting, Self.Node: BackwardLinked & UnlinkableNode & DataReference {
    init<S>(_ elements: S) where S: Sequence, S.Element == Node.DataType {
        self.init()
        append(contentsOf: elements)
    }

    mutating func append<S>(contentsOf newElements: S) where S: Sequence, S.Element == Node.DataType {
        for element in newElements {
            append(element)
        }
    }

    mutating func replaceSubrange<C>(_ subrange: Range<NodeIndex<Node>>, with newElements: C) where C: Collection, C.Element == Node.DataType {
        var position = subrange.lowerBound.node ?? head
        let lastToRemove = subrange.upperBound.node?.previous ?? tail
        if position === head && lastToRemove === tail {
            removeAll()
            for element in newElements { append(element) }
            return
        }

        var insertAfter = position?.previous

        while let node = position {
            position = node.next
            remove(node: node)
            if node === lastToRemove { break }
        }
        for element in newElements {
            let newNode = Node(element)
            if let insertAfter = insertAfter {
                insert(node: newNode, after: insertAfter)
            } else {
                insertAsHead(newNode)
            }
            insertAfter = newNode
        }
    }
}

public extension RangeReplaceableNodeList where Self: SentinelNodeList, Self: DepthCounting, Self.Node == NodeOrSentinel<Element> {
    var isEmpty: Bool { return headSentinel.next === tailSentinel }

    mutating func replaceSubrange<C>(_ subrange: Range<NodeIndex<Node>>, with newElements: C) where C: Collection, C.Element == Self.Element {
        var insertAfter = subrange.lowerBound.node?.previous ?? headSentinel
        var position = insertAfter.next
        let endBefore = subrange.upperBound.node ?? tailSentinel
        while let node = position, !(node === endBefore) {
            position = node.next
            remove(node: node)
        }
        for element in newElements {
            let newNode = Node(element)
            insert(node: newNode, after: insertAfter)
            insertAfter = newNode
        }
    }
}

// These are just to avoid ambiguity with multiple default implementations:

public extension Collection where Self: LinkedNodeList {
    var isEmpty: Bool { return head == nil }
}

public extension Collection where Self: LinkedNodeList, Self.Node: DataReference, Self.Node.DataType == Self.Iterator.Element {
    var first: Node.DataType? { return head?.data }
}

public extension BidirectionalCollection where Self: LinkedNodeList, Self.Node: DataReference, Self.Node.DataType == Self.Iterator.Element {
    var last: Node.DataType? { return tail?.data }
}

public extension RangeReplaceableCollection where Self: LinkedNodeList, Self.Node: DataReference {
    mutating func append(_ element: Node.DataType) {
        append(node: Node(element))
    }

    @discardableResult
    mutating func removeFirst() -> Node.DataType {
        return removeFirstNode().data
    }
}

public extension RangeReplaceableNodeList where Self.Node: DataReference & BackwardLinked & UnlinkableNode {
    @discardableResult
    mutating func popLast() -> Node.DataType? {
        return popLastNode()?.data
    }

    @discardableResult
    mutating func removeLast() -> Node.DataType {
        return removeLastNode().data
    }
}
