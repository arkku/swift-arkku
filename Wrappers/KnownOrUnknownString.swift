//
// KnownOrUnknownString.swift
//
// Introduces the generic enum `KnownOrUnknownString`, which is intended
// as a `Codable` wrapper for `String` enums of `known` cases, while
// allowing arbitrary unknown values as the `unknown` case.
//
// For example:
//
//      enum KnownFooKey: String { case foo, bar, baz }
//      typealias FooKey = KnownOrUnknownString<KnownFooKey>
//      let known: FooKey = FooKey(.foo)
//      let known2: FooKey = FooKey("foo")
//      let unknown: FooKey = FooKey("quux")
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

/// A type representing either a known set of values as an `enum` of `String`
/// type, or an unknown value as a `String`. These are encoded as strings,
/// which means that when more known cases are added, the same value may turn
/// from unknown to known upon decoding.
public enum KnownOrUnknownString<KnownValue: RawRepresentable>: RawRepresentable where KnownValue.RawValue == String {
    public typealias RawValue = KnownValue.RawValue

    /// A known value.
    case known(KnownValue)

    /// An unknown value.
    ///
    /// Note that the `unknown` case should not be created directly:
    /// use the constructor from `String` instead.
    case unknown(String)

    /// Init as a `known` value if `string` is a known value, otherwise
    /// as an `unknown` value with `string`.
    public init(_ string: String) {
        if let knownValue = KnownValue(rawValue: string) {
            self = .known(knownValue)
        } else {
            self = .unknown(string)
        }
    }

    public init?(rawValue: RawValue) {
        self.init(rawValue)
    }

    public var rawValue: RawValue {
        switch self {
        case .known(let value): return value.rawValue
        case .unknown(let value): return value
        }
    }
}

extension KnownOrUnknownString: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case .known(let known):     return ".\(known)"
        case .unknown(let string):  return string.debugDescription
        }
    }

    public var debugDescription: String {
        return description
    }
}

extension KnownOrUnknownString: Hashable, Equatable, Comparable {
    public static func == (lhs: KnownOrUnknownString<KnownValue>, rhs: KnownOrUnknownString<KnownValue>) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public static func < (lhs: KnownOrUnknownString<KnownValue>, rhs: KnownOrUnknownString<KnownValue>) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}

extension KnownOrUnknownString: Codable { }

extension KnownOrUnknownString: CodingKey {
    public var stringValue: String {
        return rawValue
    }

    public var intValue: Int? {
        return nil
    }

    public init(stringValue string: String) {
        self.init(string)
    }

    public init?(intValue: Int) {
        return nil
    }
}

/// A type that has known values.
///
/// This exists mainly so that it is possible to extend `Dictionary` to
/// be accessed with the known values of `KnownOrUnknownString`.
public protocol Knowable {
    associatedtype KnownValue: RawRepresentable

    /// Init as a `known` value.
    init(_ knownValue: KnownValue)

    /// Returns the unwrapped known value if this is a `known` case,
    /// otherwise returns `nil`.
    var known: KnownValue? { get }
}

extension KnownOrUnknownString: Knowable {
    public init(_ knownValue: KnownValue) {
        self = .known(knownValue)
    }

    public var known: KnownValue? {
        guard case .known(let knownValue) = self else { return nil }
        return knownValue
    }
}

/// A type that can always be initialized from a `String`.
///
/// This exists mainly so that it is possible to extend `Dictionary` to
/// be accessed with the unknown values of `KnownOrUnknownString`.
public protocol AnyStringInitable {
    /// Init from `string`.
    init(stringValue string: String)
}

extension KnownOrUnknownString: AnyStringInitable { }

extension AnyStringInitable {
    public init(stringLiteral value: String) {
        self.init(stringValue: value)
    }
}

extension KnownOrUnknownString: ExpressibleByStringLiteral { }

extension Collection where Index: Knowable {
    /// Access the element for `knownIndex`.
    public subscript(_ knownIndex: Index.KnownValue) -> Element {
        return self[Index(knownIndex)]
    }
}

extension MutableCollection where Index: Knowable {
    /// Access the element for `knownIndex`.
    public subscript(_ knownIndex: Index.KnownValue) -> Element {
        get {
            return self[Index(knownIndex)]
        }
        set {
            self[Index(knownIndex)] = newValue
        }
    }
}

/// A protocol for helper extensions. This is used so that instead of
/// being specific to `Dictionary`, other structures providing a
/// dictionary-like interface can benefit by declaring conformance.
public protocol KeyValueMap {
    associatedtype Key: Hashable
    associatedtype Value

    init<S>(uniqueKeysWithValues: S) where S: Sequence, S.Element == (Key, Value)

    subscript(_ key: Key) -> Value? { get set }
    mutating func removeValue(forKey key: Key) -> Value?
    mutating func updateValue(_ value: Value, forKey key: Key) -> Value?
}

extension Dictionary: KeyValueMap { }

extension KeyValueMap where Key: Knowable {
    /// Access the element for `knownKey`.
    public subscript(_ knownKey: Key.KnownValue) -> Value? {
        get {
            return self[Key(knownKey)]
        }
        set {
            self[Key(knownKey)] = newValue
        }
    }

    /// Remove the value for `knownKey`.
    @discardableResult
    public mutating func removeValue(forKey knownKey: Key.KnownValue) -> Value? {
        return removeValue(forKey: Key(knownKey))
    }

    /// Update `value` for `knownKey`.
    public mutating func updateValue(_ value: Value, forKey knownKey: Key.KnownValue) -> Value? {
        return updateValue(value, forKey: Key(knownKey))
    }
}

extension Dictionary where Key: Knowable {
    /// Remove all values for unknown keys.
    public mutating func removeUnknownKeys() {
        self = filter { $0.key.known != nil }
    }

    /// Filters out all unknown keys.
    public func unknownKeysRemoved() -> [Key: Value] {
        return filter { $0.key.known != nil }
    }
}

extension KeyValueMap where Key: Knowable, Key.KnownValue: Hashable {
    /// Prepare with the contents of `dictionary`.
    public init(_ dictionary: [Key.KnownValue: Value]) {
        self.init(uniqueKeysWithValues: dictionary.map { (Key($0), $1) })
    }
}

extension Dictionary where Key: Knowable, Key.KnownValue: Hashable {
    /// Filters out all unknown keys, and returns the result keyed
    /// by the unwrapped known keys.
    public func keyedByKnown() -> [Key.KnownValue: Value] {
        return [Key.KnownValue: Value](uniqueKeysWithValues:
            unknownKeysRemoved().map { ($0.known!, $1) })
    }
}

extension Collection where Index: AnyStringInitable {
    /// Access the element for `string`.
    public subscript(_ string: String) -> Element {
        return self[Index(stringValue: string)]
    }
}

extension KeyValueMap where Key: AnyStringInitable {
    /// Prepare with the contents of `dictionary`.
    public init(_ dictionary: [String: Value]) {
        self.init(uniqueKeysWithValues: dictionary.map { (Key(stringValue: $0), $1) })
    }

    /// Access the element for `string`.
    public subscript(_ string: String) -> Value? {
        get {
            return self[Key(stringValue: string)]
        }
        set {
            self[Key(stringValue: string)] = newValue
        }
    }

    /// Remove the value for `string`.
    @discardableResult
    public mutating func removeValue(forKey string: String) -> Value? {
        return removeValue(forKey: Key(stringValue: string))
    }
}

