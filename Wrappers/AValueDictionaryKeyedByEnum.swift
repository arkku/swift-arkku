//
// AValueDictionaryKeyedByEnum.swift
// Requires: `AValue.swift` and `DictionaryKeyedByEnum.swift`
//
// This extends `MapCoded` with the same facilities for automatic wrapping
// and unwrapping of `AValue` as is found in `Dictionary`.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

extension MapCoded: Valuable where Key.RawValue == String, Value: Valuable {
    public var asValue: AValue {
        return dictionary.asValue
    }
}

extension MapCoded: Devaluable where Key.RawValue == String, Value: Devaluable {
    public init?(unwrapping value: AValue) {
        guard let unwrapped = WrappedDictionary(unwrapping: value) else {
            return nil
        }
        self.dictionary = unwrapped
    }
}

extension MapCoded where Value == AValue {
    /// Init from `dictionary` with the values wrapped in `AValue`.
    public init(wrapping dictionary: [Key: Valuable]) {
        self.init(dictionary.mapValues { $0.asValue })
    }

    /// Access wrapped `ValueCodable` types directly. Note that this does not
    /// distinguish between values that are missing and those that can't
    /// be unwrapped to the correct type.
    public subscript<T>(wrapped key: Key) -> T? where T: ValueCodable {
        get { return dictionary[wrapped: key] }
        set { dictionary[wrapped: key] = newValue }
    }

    /// Remove the value for `key`, and return the unwrapped value that was removed.
    public mutating func removeUnwrappedValue<T>(forKey key: Key) -> T? where T: Devaluable {
        return dictionary.removeUnwrappedValue(forKey: key)
    }

    /// Update the wrapped `value` for `key`.
    public mutating func updateValue<T>(wrapped value: T, forKey key: Key) -> T? where T: ValueCodable {
        return dictionary.updateValue(wrapped: value, forKey: key)
    }
}
