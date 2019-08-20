//
// AValueKeyedByKnowable.swift
// Requires: `AValue.swift` and `KnownOrUnknownString.swift`.
//
// Helper extensions for the combination of `AValue` values and
// `KnownOrUnknownString` keys.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

extension KeyValueMap where Key: Knowable, Key.KnownValue: Hashable, Value == AValue {
    /// Prepare with the contents of `dictionary`.
    public init(_ dictionary: [Key.KnownValue: Valuable]) {
        self.init(uniqueKeysWithValues: dictionary.map { (Key($0), $1.asValue) })
    }

    /// Access wrapped `ValueCodable` types directly. Note that this does not
    /// distinguish between values that are missing and those that can't
    /// be unwrapped to the correct type.
    public subscript<T>(wrapped key: Key.KnownValue) -> T? where T: ValueCodable {
        get {
            guard let value = self[Key(key)] else { return nil }
            return value.unwrapped()
        }
        set {
            self[Key(key)] = newValue?.asValue
        }
    }

    /// Update the wrapped `value` for `knownKey`.
    public mutating func updateValue<T>(wrapped value: T, forKey knownKey: Key.KnownValue) -> T? where T: ValueCodable {
        return updateValue(value.asValue, forKey: Key(knownKey))?.unwrapped()
    }
}

extension KeyValueMap where Key: AnyStringInitable, Value == AValue {
    /// Prepare with the wrapped contents of `dictionary`.
    public init(wrapping dictionary: [String: Valuable]) {
        self.init(uniqueKeysWithValues: dictionary.map { (Key(stringValue: $0), $1.asValue) })
    }
}

extension MutableCollection where Index: Knowable, Element == AValue {
    /// Access wrapped `ValueCodable` types directly. If the value
    /// cannot be unwrapped, `nil` is returned. It is not permitted to set
    /// the element to `nil`.
    public subscript<T>(wrapped index: Index.KnownValue) -> T? where T: ValueCodable {
        get {
            let value = self[Index(index)]
            return value.unwrapped()
        }
        set {
            self[Index(index)] = newValue!.asValue
        }
    }
}

extension KnownOrUnknownString: ValueCodable, StringRepresentable { }
