//
// LinkedNodes.swift
// Requires: `DataStructures.swift`
//
// Building blocks for linked lists.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

// MARK: - Node Protocols

/// A node that can be linked into a list.
public protocol LinkableNode: class {
    /// Link `node` after this node in the list.
    func linkNext(_ node: Self?)
}

/// A node linked forward.
public protocol ForwardLinked: LinkableNode {
    /// The next node in the list.
    var next: Self? { get set }

    /// Unlinks the next node in the list, updating links in any
    /// linked nodes to maintain list consistency.
    func unlinkNext()
}

/// A node linked backward.
public protocol BackwardLinked: LinkableNode {
    /// The previous node in the list.
    var previous: Self? { get set }
}

/// A node that can be unlink itself from the list while maintaining
/// consistency of the list. This is typically the case only in a
/// doubly linked list.
public protocol UnlinkableNode: class {
    /// Unlinks this node from the list, updating links of any
    /// linked nodes to maintain list consistency.
    func unlink()
}

/// A doubly linked node.
public typealias DoublyLinked = ForwardLinked & BackwardLinked & UnlinkableNode

// MARK: - Node Protocol Extensions

public extension ForwardLinked {
    /// Is this the last node in the list?
    var isLast: Bool { return next == nil }
}

public extension BackwardLinked {
    /// Is this the first node in the list?
    var isFirst: Bool { return previous == nil }
}

public extension BackwardLinked where Self: ForwardLinked {
    func unlink() {
        let oldPrevious = previous
        let oldNext = next
        oldPrevious?.next = next
        next = nil
        oldNext?.previous = oldPrevious
        previous = nil
    }
}

public extension ForwardLinked where Self: UnlinkableNode {
    func unlinkNext() {
        next?.unlink()
    }
}

public extension ForwardLinked where Self: BackwardLinked {
    func linkNext(_ node: Self?) {
        node?.previous = self
        next = node
    }

    func linkAfter(_ previousNode: Self) {
        linkNext(previousNode.next)
        previousNode.linkNext(self)
    }

    func linkBefore(_ nextNode: Self) {
        let previousNode = nextNode.previous
        linkNext(nextNode)
        previousNode?.linkNext(self)
    }
}

public extension ForwardLinked {
    func linkNext(_ node: Self?) {
        next = node
    }

    func unlinkNext() {
        guard let oldNext = next else { return }

        next = oldNext.next
        oldNext.next = nil
    }

    func linkBefore(_ nextNode: Self) {
        linkNext(nextNode)
    }
}

// MARK: - Iterators

public struct ForwardLinkIterator<Node: ForwardLinked & DataReference>: IteratorProtocol, Sequence {
    public init(_ startNode: Node?) {
        position = startNode
    }

    private var position: Node?

    public mutating func next() -> Node.DataType? {
        guard let node = position else { return nil }
        position = node.next
        return node.data
    }

    public func makeIterator() -> ForwardLinkIterator<Node> {
        return self
    }
}

public extension ForwardLinked where Self: DataReference {
    typealias ForwardIterator = ForwardLinkIterator<Self>

    func makeIterator() -> ForwardIterator {
        return ForwardIterator(self)
    }
}

public struct BackwardLinkIterator<Node: BackwardLinked & DataReference>: IteratorProtocol, Sequence {
    public init(_ startNode: Node?) {
        position = startNode
    }

    private var position: Node?

    public mutating func next() -> Node.DataType? {
        guard let node = position else { return nil }
        position = node.previous
        return node.data
    }

    public func makeIterator() -> BackwardLinkIterator<Node> {
        return self
    }
}

public extension BackwardLinked where Self: DataReference {
    typealias BackwardIterator = BackwardLinkIterator<Self>

    func makeBackwardIterator() -> BackwardIterator {
        return BackwardIterator(self)
    }
}

// MARK: - Linked Nodes

/// A node with associated data.
open class DataNode<DataType: Any>: DataReference, CustomStringConvertible {
    /// Initialize a node holding `data`.
    public required init(_ data: DataType) {
        self.data = data
    }

    /// The node's data.
    public var data: DataType

    public var description: String {
        return "\(data)"
    }
}

/// A node in a linked list. Since this is a `Sequence`, it can be
/// used as the simplest form of linked list on its own, but then
/// the empty list becomes a special case which must be handled
/// separately (one possibility is to use a dummy node).
public final class LinkedNode<DataType: Any>: DataNode<DataType>, ForwardLinked, Sequence {
    public var next: LinkedNode<DataType>?
}

/// A doubly-linked node in a linked list. The backward link, i.e.,
/// `previous`, is a weak reference to avoid retain cycles.
public final class DoublyLinkedNode<DataType: Any>: DataNode<DataType>, DoublyLinked, Sequence {
    public var next: DoublyLinkedNode<DataType>?

    public weak var previous: DoublyLinkedNode<DataType>?
}

public protocol DataOrSentinelNode: DataOrSentinel, DoublyLinked {
    /// The data element, or `nil` if this is a sentinel node.
    var element: DataType? { get set }

    /// Prepare a sentinel node.
    init()

    /// Prepare a data node.
    init(_ data: DataType)
}

public extension DataOrSentinelNode {
    /// The data element of this node. Accessing this on a sentinel node
    /// is a runtime error (see `isSentinel` and `element`).
    var data: DataType {
        get { return element! }
        set { element = newValue }
    }

    /// Is this a sentinel node without data?
    var isSentinel: Bool {
        return element == nil
    }

    func makeIterator() -> SentinelForwardIterator<Self> {
        return SentinelForwardIterator(position: self)
    }

    func makeBackwardIterator() -> SentinelReverseIterator<Self> {
        return SentinelReverseIterator(position: self)
    }
}

public struct SentinelForwardIterator<Node: DataOrSentinelNode>: IteratorProtocol, Sequence {
    public mutating func next() -> Node.DataType? {
        guard let data = position?.element else { return nil }
        position = position?.next
        return data
    }

    var position: Node?
}

public struct SentinelReverseIterator<Node: DataOrSentinelNode>: IteratorProtocol, Sequence {
    public mutating func next() -> Node.DataType? {
        guard let data = position?.element else { return nil }
        position = position?.previous
        return data
    }

    var position: Node?
}

/// A doubly-linked node that may also be a sentinel node, i.e., an empty node
/// at the beginning and the end of the list to simplify implementation.
public final class NodeOrSentinel<DataType: Any>: DataOrSentinelNode, Sequence, CustomStringConvertible {
    public var next: NodeOrSentinel<DataType>?

    public weak var previous: NodeOrSentinel<DataType>?

    public var element: DataType?

    /// Prepare a sentinel node.
    public required init() {
        self.element = nil
    }

    /// Prepare a node with `data`.
    public required init(_ data: DataType) {
        self.element = data
    }

    public var description: String {
        return isSentinel ? "||" : "\(data)"
    }
}
