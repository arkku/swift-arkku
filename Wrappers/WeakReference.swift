//
// WeakReference.swift
//
// Copyright © 2016 Kimmo Kulovesi. All rights reserved.
//

/// Weak reference wrapper (e.g., to store weak references in a collection
/// that uses strong references).
final class Weak<ReferredType>: Equatable, CustomStringConvertible where ReferredType: AnyObject {
    public weak var reference: ReferredType?

    public init(_ reference: ReferredType) {
        self.reference = reference
    }

    public static func ==(lhs: Weak, rhs: Weak) -> Bool {
        return lhs.reference === rhs.reference
    }

    public var description: String {
        return "weak(\(reference == nil ? "(nil)" : "\(reference!)"))"
    }
}
