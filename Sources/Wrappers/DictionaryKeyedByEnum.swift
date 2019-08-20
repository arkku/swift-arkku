//
// DictionaryKeyedByEnum.swift
//
// At the time of writing there is a problem with encoding dictionaries keyed
// by anything other than an actual `String` or `Int`: the encoding will be as
// an array of alternating keys and values. This breaks keying by things like
// enums that have `String` or `Int` raw values.
//
// This file introduces `MapCoded` as a wrapper for such a dictionary,
// forcing it to be encoded and decoded as a map. The wrapper is very
// light-weight; only the decoding needs to creatie an intermediate dictionary.
//
// Note that you should make your key `enum` conform to `CodingKey` to use the
// `Encodable` implementation.
//
// See: https://bugs.swift.org/browse/SR-7788
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

public struct MapCoded<Key, Value> where Key: RawRepresentable, Key: Hashable, Key.RawValue: Hashable {
    /// The type of the raw value of the keys.
    public typealias RawKey = Key.RawValue

    public typealias WrappedDictionary = [Key: Value]

    /// The wrapped dictionary, that can be accessed and modified freely.
    public var dictionary: WrappedDictionary

    /// Wrap `dictionary` in a way that ensures coding as a map.
    public init(_ dictionary: WrappedDictionary) {
        self.dictionary = dictionary
    }

    /// Wrap a dictionary made from the `sequence` of keys and values.
    public init<S>(uniqueKeysWithValues sequence: S) where S : Sequence, S.Element == (Key, Value) {
        self.dictionary = WrappedDictionary(uniqueKeysWithValues: sequence)
    }

    /// A new dictionary with the same values keyed by the raw keys.
    public func dictionaryKeyedByRaw() -> [RawKey: Value] {
        return [RawKey: Value](uniqueKeysWithValues: dictionary.map { ($0.rawValue, $1) })
    }

    /// Access the value associated with `key`.
    public subscript(_ key: Key) -> Value? {
        get { return dictionary[key] }
        set { dictionary[key] = newValue }
    }

    /// Remove the value associated with `key`.
    /// Returns the old value, or `nil` if it didn't exist.
    @discardableResult
    public mutating func removeValue(forKey key: Key) -> Value? {
        return dictionary.removeValue(forKey: key)
    }

    /// Update the value associated with `key` to `value`.
    /// Returns the old value, or `nil` if it didn't exist.
    public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        return dictionary.updateValue(value, forKey: key)
    }
}

extension MapCoded: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return dictionary.description
    }

    public var debugDescription: String {
        return "Map\(dictionary.debugDescription)"
    }
}

extension MapCoded {
    /// Access the value associated with the key corresponding to `rawKey`.
    /// When assigning, `rawKey` must map to a valid key.
    public subscript(_ rawKey: RawKey) -> Value? {
        get {
            guard let key = Key(rawValue: rawKey) else { return nil }
            return dictionary[key]
        }
        set {
            dictionary[Key(rawValue: rawKey)!] = newValue
        }
    }

    /// Remove the value associated with the key corresponding to `rawKey`.
    /// Returns the old value, or `nil` if it didn't exist.
    @discardableResult
    public mutating func removeValue(forKey rawKey: RawKey) -> Value? {
        guard let key = Key(rawValue: rawKey) else { return nil }
        return dictionary.removeValue(forKey: key)
    }
}

extension MapCoded: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.dictionary = [Key: Value](uniqueKeysWithValues: elements)
    }
}

extension Dictionary where Key: RawRepresentable, Key.RawValue: Hashable {
    /// This dictionary wrapped in `MapCoded`, which is always encoded as a map.
    public var wrappedAsMapCoded: MapCoded<Key, Value> {
        return MapCoded(self)
    }
}

extension MapCoded: Decodable where Key.RawValue: Decodable, Value: Decodable {
    public init(from decoder: Decoder) throws {
        let rawDictionary = try [RawKey: Value](from: decoder)
        self.dictionary = try [Key: Value](uniqueKeysWithValues: rawDictionary.map { rawKey, value in
            guard let key = Key(rawValue: rawKey) else {
                throw DecodingError.typeMismatch(Key.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Raw value (\(rawKey)) not convertible to \(Key.self)"))
            }
            return (key, value)
        })
    }
}

extension MapCoded: Encodable where Key: CodingKey, Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        for (key, value) in dictionary {
            try container.encode(value, forKey: key)
        }
    }
}

extension MapCoded: Equatable where Value: Equatable { }
extension MapCoded: Hashable where Value: Hashable { }

extension MapCoded: Collection {
    public typealias Index = WrappedDictionary.Index
    public typealias Element = WrappedDictionary.Element
    public typealias SubSequence = WrappedDictionary.SubSequence
    public var startIndex: Index { return dictionary.startIndex }
    public var endIndex: Index { return dictionary.endIndex }
    public func index(after i: Index) -> Index { return dictionary.index(after: i) }
    public subscript(position: Index) -> Element {
        return dictionary[position]
    }
}
