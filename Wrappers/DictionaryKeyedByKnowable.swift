//
// DictionaryKeyedByKnowable.swift
// Requires: `KnownOrUnknownString.swift` and `DictionaryKeyedByEnum.swift`
//
// This extends `MapCoded` with helpers for use with `Knowable` keys.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

extension MapCoded: KeyValueMap { }

extension MapCoded where Key: Knowable {
    /// Remove all values for unknown keys.
    public mutating func removeUnknownKeys() {
        dictionary.removeUnknownKeys()
    }

    /// Filters out all unknown keys.
    public func unknownKeysRemoved() -> MapCoded<Key, Value> {
        return MapCoded(dictionary.unknownKeysRemoved())
    }
}

extension MapCoded where Key: Knowable, Key: RawRepresentable, Key.KnownValue: Hashable, Key.KnownValue.RawValue: Hashable {
    /// Filters out all unknown keys, and returns the result keyed
    /// by the unwrapped known keys.
    public func keyedByKnown() -> MapCoded<Key.KnownValue, Value> {
        return MapCoded<Key.KnownValue, Value>(uniqueKeysWithValues: unknownKeysRemoved().map { ($0.known!, $1) })
    }
}
