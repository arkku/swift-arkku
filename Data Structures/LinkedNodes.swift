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
    public var isLast: Bool { return next == nil }
}

public extension BackwardLinked {
    /// Is this the first node in the list?
    public var isFirst: Bool { return previous == nil }
}

public extension BackwardLinked where Self: ForwardLinked {
    public func unlink() {
        next?.previous = previous
        previous?.next = next
        previous = nil
        next = nil
    }
}

public extension ForwardLinked where Self: UnlinkableNode {
    public func unlinkNext() {
        next?.unlink()
    }
}

public extension ForwardLinked where Self: BackwardLinked {
    public func linkNext(_ node: Self?) {
        node?.previous = self
        next = node
    }
}

public extension ForwardLinked {
    public func linkNext(_ node: Self?) {
        next = node
    }

    public func unlinkNext() {
        guard let oldNext = next else { return }

        next = oldNext.next
        oldNext.next = nil
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
    public typealias ForwardIterator = ForwardLinkIterator<Self>

    public func makeIterator() -> ForwardIterator {
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
    public typealias BackwardIterator = BackwardLinkIterator<Self>

    public func makeBackwardIterator() -> BackwardIterator {
        return BackwardIterator(self)
    }
}

// MARK: - Linked Nodes

/// A node with associated data.
public class DataNode<DataType: Any>: DataReference, CustomStringConvertible {
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

/// A doubly linked node in a linked list. The backward link, i.e.,
/// `previous`, is a weak reference to avoid retain cycles.
public final class DoublyLinkedNode<DataType: Any>: DataNode<DataType>, DoublyLinked, Sequence {
    public var next: DoublyLinkedNode<DataType>?

    public weak var previous: DoublyLinkedNode<DataType>?
}
