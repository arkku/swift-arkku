//
// JSONHelpers.swift
//
// Extends `JSONEncoder` and `JSONDecoder` with helpers to encode and decode
// to/from `String` instead of `Data`.
//
// Extends `JSONEncoder` to allow encoding a plain `String` without any
// container. This is technically against the JSON spec, but can be helpful
// for "JSON escaping" a string.
//
// Also adds some helpers to `KeyedDecodingContainer` with fallback default
// values, for quickly implementing custom decoding of non-optional properties.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

// MARK: - JSON String

public extension JSONEncoder {
    /// Encode `value` into a JSON string.
    public func encodedString<T: Encodable>(from value: T) throws -> String {
        let data = try encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(data, .init(codingPath: [], debugDescription: "Result not UTF-8"))
        }
        return string
    }
}

public extension JSONDecoder {
    /// Decode `string` into an object of the given `type`.
    public func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "String not UTF-8"))
        }
        return try decode(type, from: data)
    }
}

// MARK: - String into JSON

public extension JSONEncoder {
    /// Encode `string` into a JSON fragment without any container.
    public func encode(string: String) -> Data {
        let wrappedString: [String] = [ string ]
        guard var encoded = try? encode(wrappedString) else { return Data() }

        // This is quite silly, but `JSONEncoder` is enforcing the strict
        // interpretation of the JSON spec that the top level container must
        // be an array or a dictionary, so we need to encode the string enclosed
        // in one, and then remove the container from the encoded data.
        let quote: UInt8 = 0x22
        guard let lastQuote = encoded.lastIndex(of: quote) else { return Data() }
        encoded = encoded.prefix(through: lastQuote)
        guard let firstQuote = encoded.firstIndex(of: quote) else { return Data() }
        encoded = encoded.suffix(from: firstQuote)
        return encoded
    }

    /// Encode `string` into a JSON fragment without any container.
    public func encodedString(fromString string: String) -> String {
        let data = encode(string: string)
        guard let string = String(data: data, encoding: .utf8) else { return "" }
        return string
    }
}

// MARK: - Decode with Default

public extension KeyedDecodingContainer {
    /// Attempt to decode the value for `key` if present. If `key` is not
    /// present, returns `defaultValue`. If `key` is present but not decodable
    /// to this type, returns `nil`.
    public func decode<T>(key: K, valueIfMissing defaultValue: T) throws -> T? where T: Decodable {
        if let value = try decodeIfPresent(T.self, forKey: key) {
            return value
        }
        return contains(key) ? nil : defaultValue
    }

    /// Attempt to decode the value for `key` if present. If `key` is not
    /// present or cannot be decoded for any reason, returns `defaultValue`.
    public func decode<T>(key: K, fallback defaultValue: T) -> T where T: Decodable {
        if let v = try? decodeIfPresent(T.self, forKey: key), let value = v {
            return value
        }
        return defaultValue
    }
}

