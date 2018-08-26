//
// MulticastDelegates.swift
// Requires: `WeakReference.swift`
//
// A container for multiple weak references to delegates.
//
// Copyright © 2016 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

/// A set of multicast delegates held as weak references.
public final class MulticastDelegates<DelegateProtocol>: CustomStringConvertible {
    var delegates = [Weak<AnyObject>]()

    public init() { }

    /// Invokes `closure` for each delegate synchronously.
    public func perform(_ closure: (DelegateProtocol) -> Void) {
        var needsCleaning = false
        for weakDelegate in delegates {
            guard let strongDelegate = weakDelegate.reference as? DelegateProtocol else {
                needsCleaning = true
                continue
            }
            closure(strongDelegate)
        }
        if needsCleaning {
            removeExpiredDelegates()
        }
    }

    /// Invokes `closure` asynchronously on `queue` (default `main`) for
    /// each delegate.
    public func async(on queue: DispatchQueue = .main, _ closure: @escaping (DelegateProtocol) -> Void) {
        var needsCleaning = false
        for weakDelegate in delegates {
            guard let strongDelegate = weakDelegate.reference as? DelegateProtocol else {
                needsCleaning = true
                continue
            }
            queue.async { closure(strongDelegate) }
        }
        if needsCleaning {
            removeExpiredDelegates()
        }
    }

    /// Add `newDelegate` to set of delegates.
    public func add(_ newDelegate: DelegateProtocol) {
        var alreadyExists = false
        delegates = delegates.filter { weakDelegate in
            guard let strongDelegate = weakDelegate.reference else {
                return false
            }
            if strongDelegate === newDelegate as AnyObject {
                alreadyExists = true
            }
            return true
        }
        if !alreadyExists {
            delegates.append(Weak(newDelegate as AnyObject))
        }
    }

    /// Remove `delegate` from the set of delegates.
    public func remove(_ delegate: DelegateProtocol) {
        delegates = delegates.filter { weakDelegate in
            guard let strongDelegate = weakDelegate.reference else {
                return false
            }
            return !(strongDelegate === delegate as AnyObject)
        }
    }

    /// Make the set of delegates empty.
    public func removeAll() {
        delegates.removeAll()
    }

    /// Clean up expired weak references to delegates.
    public func removeExpiredDelegates() {
        delegates = delegates.filter { $0.reference != nil }
    }

    /// The number of delegates registered (may include expired weak references).
    public var count: Int { return delegates.count }

    /// Are there any registered delegates (may include expired weak references)?
    public var isEmpty: Bool { return delegates.isEmpty }

    public var description: String {
        return "Delegates\(delegates)"
    }

}
