//
// AValue.swift
//
// Introduces the type `AValue`, which is a `Codable` wrapper for various
// types, in particular those typically found in nested JSON and MessagePack
// structures. This allows defining dictionaries and arrays with mixed types as
// containing `AValue` instead of `Any`, and still have them automatically
// `Codable`.
//
// The protocols `Valuable` and `Devaluable` - pardon the naming - are the
// equivalent of `Encodable` and `Decodable` for wrapping in `AValue`, and
// their combination, `ValueCodable`, is declared here for pretty much every
// type supported by JSON, as well as for arrays and dictionaries of these
// types, nested.
//
// As an example if you have a dictionary with mixed types of values, you can
// use `[String: AValue]` as the type and get `Codable` support automatically.
// Access would then be, e.g., `dictionary["someString"]?.stringValue` or
// `let myInt: Int16? = dictionary["someInt"]?.unwrapped()`.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

/// Let us define a wrappable integer as something that will fit in a signed
/// 64-bit integer. Now we can greatly simplify things by only having one
/// integer case for `AValue`.
public typealias Integer = Int64

// MARK: - AValue

/// A wrapper for a value of any supported codable type. This is intended to
/// be used in `Codable` entities instead of `Any`, as it allows for automatic
/// conformance to `Codable`, as well as provides easy ways for type-checking
/// the decoded values (e.g., instead of having to check for various integer
/// types from `Any`, it is possible to either check or the case `integer` or
/// use the accessor `integerValue`. The accessor `anyValue` is also provided
/// to allow reverting to `Any`, but it is recommended to use the specific
/// accessors, or `unwrapped`.
///
/// It is important to understand that this is a transparent wrapper in
/// encoding, which means that it may not be fully reversible in all encodings,
/// such as JSON. For example, a `date` value is typically encoded as a string
/// or as a number, and becomes indistinguishable from that type. To mitigate
/// this, there are accessors provided that do conversion between types.
///
/// See also `ValueCodable`.
public enum AValue: Codable {

    /// A string value.
    case string(String)

    /// An integer value.
    case integer(Integer)

    // A floating point value.
    case float(Double)

    /// A date value.
    ///
    /// Note: When decoding, it is likely that dates end up as either `string`
    /// or `integer` values, unless the encoding supports a date type natively.
    /// The accessor `dateValue` will convert integers and floats automatically,
    /// and as such it is recommended to use those representations, as
    /// `millisecondsSince1970`, for encoding to JSON and other formats without
    /// a date type.
    case date(Date)

    /// A `Data` value.
    ///
    /// Note: When decoding, it is likely that data values end up as either
    /// `string` or `array` values, unless the encoding supports a data type
    /// natively. It is not possible in general to automatically distinguish
    /// between such encoded data and strings or arrays that happen to have
    /// similar contents. As such I recommend making `Data` conform to
    /// `ValueCodable` with a constructor that handles both a `data` value and
    /// the known encoding (e.g., a `string` value with base-64 encoded
    /// contents).
    case data(Data)

    /// An array of values.
    case array([AValue])

    /// A dictionary of values with string keys.
    case dictionary([String: AValue])

    /// A boolean value.
    case boolean(Bool)

    /// Try to wrap `value` in the most appropriate type.
    ///
    /// Note that as a special case, arrays of bytes (`UInt8`) passed here are converted
    /// to `data` values instead of `array`. You can obtain an `array` value by calling
    /// `asValue` on the array itself.
    public init?(_ value: Any) {
        switch value {
        case let byteArray as [UInt8]:
            // As a special case, an array of `UInt8` turns into `data`, instead of
            // an `array`. It is possible to circumvent this with `asValue`.
            self = .data(Data(byteArray))
        case let valuable as Valuable:
            self = valuable.asValue
        case let value as AValue:
            self = value
        case let array as [Any]:
            guard let valueArray: [AValue] = (try? array.map { element in
                guard let value = AValue(element) else { throw ValueError() }
                return value
            }) else { return nil }
            self = .array(valueArray)
        case let dictionary as [String: Any]:
            guard let valueDictionary: [String: AValue] = (try? dictionary.mapValues { anyValue in
                guard let value = AValue(anyValue) else { throw ValueError() }
                return value
            }) else { return nil }
            self = .dictionary(valueDictionary)
        default:
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let int = try? container.decode(Integer.self) {
            self = .integer(int)
        } else if let bool = try? container.decode(Bool.self) {
            self = .boolean(bool)
        } else if let dictionary = try? container.decode([String: AValue].self) {
            self = .dictionary(dictionary)
        } else if let array = try? container.decode([AValue].self) {
            self = .array(array)
        } else if let float = try? container.decode(Double.self) {
            self = .float(float)
        } else if let date = try? container.decode(Date.self) {
            self = .date(date)
        } else if let data = try? container.decode(Data.self) {
            self = .data(data)
        } else {
            throw DecodingError.valueNotFound(AValue.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Unable to decode value"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):   try container.encode(string)
        case .integer(let int):     try container.encode(int)
        case .float(let float):     try container.encode(float)
        case .date(let date):       try container.encode(date)
        case .data(let data):       try container.encode(data)
        case .dictionary(let dict): try container.encode(dict)
        case .array(let array):     try container.encode(array)
        case .boolean(let bool):    try container.encode(bool)
        }
    }

    /// The associated value recursively unwrapped, as `Any`.
    ///
    /// Note that in some cases the actual type returned may be unexpected
    /// since not all encodings are fully reversible. In general it is better
    /// to keep things wrapped and use the accessors to extract the desired
    /// types (e.g., `stringValue`), or to unwrap with `unwrapped`.
    public var anyValue: Any {
        switch self {
        case .string(let string):
            return string as Any
        case .integer(let int):
            return int as Any
        case .float(let float):
            return float as Any
        case .date(let date):
            return date as Any
        case .data(let data):
            return data as Any
        case .array(let array):
            return array.map { $0.anyValue } as [Any]
        case .dictionary(let dictionary):
            return dictionary.mapValues { $0.anyValue } as [String: Any]
        case .boolean(let bool):
            return bool as Any
        }
    }

    /// The associated string value, or `nil` if this is not a string or data
    /// value. Note that you can use `description` to get a string representation
    /// of any type of value.
    public var stringValue: String? {
        switch self {
        case .string(let string):
            return string
        case .data(let data):
            return String(data: data, encoding: .utf8)
        default:
            return nil
        }
    }

    /// The associated string value as a URL, or `nil` if there is no `stringValue`
    /// or the string value is not a valid URL.
    public var urlValue: URL? {
        guard let urlString = stringValue else { return nil }
        return URL(string: urlString)
    }

    /// The associated value as an integer, or `nil` if this is not an integer,
    /// boolean, or date value. In case of `date`, its value is returned
    /// as integer milliseconds since 1970. In case of `boolean`, the integer
    /// value is `0` for false and `1` for true.
    ///
    /// Note that while `floatValue` converts the `integer` case to float,
    /// this does _not_ convert the `float` case to integer. This is because
    /// it is possible that a value that is intended to be float can be
    /// decoded into an integer, but the opposite is very unlikely.
    public var integerValue: Integer? {
        switch self {
        case .integer(let int):     return int
        case .date(let date):       return Integer(date.timeIntervalSince1970 * 1000)
        case .boolean(let bool):    return bool ? 1 : 0
        default:                    return nil
        }
    }

    /// The associated value as floating point, or `nil` if this is not a float,
    /// integer, or date value. In case of `date`, its value is returned
    /// as milliseconds since 1970.
    public var floatValue: Double? {
        switch self {
        case .float(let float): return float
        case .integer(let int): return Double(int)
        case .date(let date):   return (date.timeIntervalSince1970 as Double) * 1000
        default:                return nil
        }
    }

    /// The associated value as a date, or `nil` if this is not a date,
    /// integer, or float value. Integer and float values are converted to
    /// dates as milliseconds since 1970.
    public var dateValue: Date? {
        switch self {
        case .date(let date):   return date
        case .integer(let int): return Date(timeIntervalSince1970: TimeInterval(int) / 1000)
        case .float(let float): return Date(timeIntervalSince1970: (float / 1000) as TimeInterval)
        default:                return nil
        }
    }

    /// The associated data value, or `nil` if this is not a data value.
    ///
    /// Note that in many encodings, such as JSON, data may be encoded as a
    /// string, which makes it unreversible without prior knowledge of which
    /// type it is, which in turn is not possible when wrapped like this.
    /// It may thus be necessary to also test for the case `string` and decode
    /// it accordingly. Likewise for encodings that use arrays of integers
    /// to represent data, although, e.g., MessagePack can differentiate those.
    ///
    /// See also the case `data` for further comments.
    public var dataValue: Data? {
        guard case .data(let value) = self else { return nil }
        return value
    }

    /// The associated array value, or `nil` if this is not an array value.
    public var arrayValue: [AValue]? {
        guard case .array(let value) = self else { return nil }
        return value
    }

    /// The associated dictionary value, or `nil` if this is not a dictionary
    /// value.
    public var dictionaryValue: [String: AValue]? {
        guard case .dictionary(let value) = self else { return nil }
        return value
    }

    /// The associated boolean value, or the boolean value of the integer or
    /// string value.
    ///
    /// NOTE: It is recommended to use only actual booleans or integers (0/1)
    /// for boolean values. This avoids the surprisingness (and computation) of
    /// interpreting strings as booleans, but the "feature" exists to help with
    /// encodings with a more limited set of types available.
    public var booleanValue: Bool? {
        switch self {
        case .boolean(let value):
            return value
        case .integer(let value):
            switch value {
            case 0:     return false
            case 1:     return true
            default:    return nil
            }
        case .string(let string):
            switch string {
            case "0", "false":  return false
            case "1", "true":   return true
            default:            return nil
            }
        default:
            return nil
        }
    }

    fileprivate struct ValueError: Error { }
}

extension AValue: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case .string(let string): return string
        case .integer(let int): return String(int)
        case .float(let float): return String(float)
        case .date(let date): return date.description
        case .data(let data): return data.description
        case .array(let array): return array.description
        case .dictionary(let dictionary): return dictionary.description
        case .boolean(let bool): return String(bool)
        }
    }

    public var debugDescription: String {
        switch self {
        case .string(let string): return string.debugDescription
        case .integer(let int): return int.description
        case .float(let float): return float.debugDescription
        case .date(let date): return date.debugDescription
        case .data(let data): return data.debugDescription
        case .array(let array): return array.debugDescription
        case .dictionary(let dictionary): return dictionary.debugDescription
        case .boolean(let bool): return bool.description
        }
    }
}

extension AValue: Equatable { }
extension AValue: Hashable { }

// MARK: - Expressible By Literal

extension AValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension AValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Integer) {
        self = .integer(value)
    }
}

extension AValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}

extension AValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .float(value)
    }
}

extension AValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AValue)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension AValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: AValue...) {
        self = .array(Array(elements))
    }
}

// MARK: - Everything Is Valuable

/// A type that can be wrapped as `AValue`, which is `Codable`.
public protocol Valuable {
    /// This wrapped as `AValue`.
    ///
    /// Note: The constructor `AValue.init(_ value: Any)` *must not* be called
    /// from the implementation, or an infinite loop will ensue.
    var asValue: AValue { get }
}

extension AValue: ValueCodable {
    /// This value.
    public var asValue: AValue { return self }

    /// Init as `value`.
    public init?(unwrapping value: AValue) {
        self = value
    }
}

public typealias ValueCodable = Valuable & Devaluable

extension String: ValueCodable {
    /// Unwrapped from the string `value`.
    public init?(unwrapping value: AValue) {
        guard let string = value.stringValue else { return nil }
        self = string
    }

    /// This string wrapped as `AValue`.
    public var asValue: AValue {
        return AValue.string(self)
    }
}

extension URL: ValueCodable {
    public init?(unwrapping value: AValue) {
        guard let urlString = value.stringValue else { return nil }
        self.init(string: urlString)
    }

    public var asValue: AValue {
        return AValue.string(absoluteString)
    }
}

extension BinaryInteger {
    /// Unwrapped from the integer `value`.
    public init?(unwrapping value: AValue) {
        guard let int = value.integerValue else { return nil }
        self.init(int)
    }

    /// This integer wrapped as `AValue`.
    public var asValue: AValue {
        return AValue.integer(Integer(self))
    }
}

extension Int: ValueCodable { }
extension UInt: ValueCodable { }
extension Int8: ValueCodable { }
extension UInt8: ValueCodable { }
extension Int16: ValueCodable { }
extension UInt16: ValueCodable { }
extension Int64: ValueCodable { }
extension UInt64: ValueCodable { }
extension Int32: ValueCodable { }
extension UInt32: ValueCodable { }

extension Double: ValueCodable {
    /// Unwrapped from the floating point `value`.
    public init?(unwrapping value: AValue) {
        guard let double = value.floatValue else { return nil }
        self = double
    }

    /// This double wrapped as `AValue`.
    public var asValue: AValue {
        return AValue.float(self)
    }
}

extension Float: ValueCodable {
    /// Unwrapped from the floating point `value`.
    public init?(unwrapping value: AValue) {
        guard let double = value.floatValue else { return nil }
        self.init(double)
    }

    /// This float wrapped as `AValue`.
    public var asValue: AValue {
        return AValue.float(Double(self))
    }
}

extension Bool: ValueCodable {
    /// Unwrapped from the boolean `value`.
    public init?(unwrapping value: AValue) {
        guard let bool = value.booleanValue else { return nil }
        self = bool
    }

    /// This boolean wrapped as `AValue`.
    public var asValue: AValue {
        return AValue.boolean(self)
    }
}

extension Date: ValueCodable {
    /// Unwrapped from the date `value`.
    public init?(unwrapping value: AValue) {
        guard let date = value.dateValue else { return nil }
        self = date
    }

    /// This date wrapped as `AValue`.
    public var asValue: AValue {
        return AValue.date(self)
    }
}

extension Data: Valuable {
    /// This data wrapped as `AValue`.
    public var asValue: AValue {
        return AValue.data(self)
    }
}

extension Array: Valuable where Element: Valuable {
    public var asValue: AValue {
        return AValue.array(map { $0.asValue })
    }
}

extension RawRepresentable where RawValue == String {
    /// Init with the unwrapped string `value`.
    public init?(unwrapping value: AValue) {
        guard let string = value.stringValue else { return nil }
        self.init(rawValue: string)
    }

    public var asValue: AValue {
        return AValue.string(rawValue)
    }
}

extension RawRepresentable where RawValue: Valuable {
    public var asValue: AValue {
        return rawValue.asValue
    }
}

extension Dictionary where Key == String, Value == AValue {
    public var asValue: AValue {
        return AValue.dictionary(self)
    }
}

extension Dictionary where Key == String, Value: Valuable {
    public var asValue: AValue {
        return AValue.dictionary(mapValues { $0.asValue })
    }
}

extension Dictionary where Key: RawRepresentable, Key.RawValue == String, Value == AValue {
    public var asValue: AValue {
        return AValue.dictionary(
            [String: AValue](uniqueKeysWithValues: map { (key: $0.rawValue, value: $1) })
        )
    }
}

extension Dictionary where Key: RawRepresentable, Key.RawValue == String, Value: Valuable {
    public var asValue: AValue {
        return AValue.dictionary(
            [String: AValue](uniqueKeysWithValues: map { (key: $0.rawValue, value: $1.asValue) })
        )
    }
}

/// Types that are `RawRepresentable` as `String` can conform to
/// `StringRepresentable` (for free) to make dictionaries keyed by them
/// automatically `ValueCodable`.
public protocol StringRepresentable: RawRepresentable, ValueCodable where RawValue == String {
}

// A string is by itself `StringRepresentable`.
extension String: StringRepresentable {
    public init?(rawValue: String) {
        self.init(rawValue)
    }

    public var rawValue: String {
        return self
    }
}

extension Dictionary: Valuable where Key: StringRepresentable, Value: Valuable { }

extension Dictionary where Key: RawRepresentable, Key.RawValue == String, Value: Devaluable {
    /// Init by unwrapping the dictionary `value`.
    public init?(unwrapping value: AValue) {
        guard let dictionary = value.dictionaryValue else { return nil }

        guard let keysAndValues: [(key: Key, value: Value)] = (try? dictionary.map { key, wrappedValue in
            guard let convertedKey = Key(rawValue: key) else { throw AValue.ValueError() }
            guard let unwrappedValue: Value = wrappedValue.unwrapped() else { throw AValue.ValueError() }
            return (key: convertedKey, value: unwrappedValue)
        }) else { return nil }

        self.init(uniqueKeysWithValues: keysAndValues)
    }
}

extension Collection where Element == AValue {
    /// Access wrapped `ValueCodable` types directly. If the value
    /// cannot be unwrapped, `nil` is returned. It is not permitted to set
    /// the element to `nil`.
    public subscript<T>(wrapped index: Index) -> T? where T: ValueCodable {
        return self[index].unwrapped()
    }
}

extension MutableCollection where Element == AValue {
    /// Access wrapped `ValueCodable` types directly. If the value
    /// cannot be unwrapped, `nil` is returned. It is not permitted to set
    /// the element to `nil`.
    public subscript<T>(wrapped index: Index) -> T? where T: ValueCodable{
        get {
            return self[index].unwrapped()
        }
        set {
            self[index] = newValue!.asValue
        }
    }
}

extension Dictionary where Value == AValue {
    /// Init from `dictionary` with the values wrapped in `AValue`.
    public init(wrapping dictionary: [Key: Valuable]) {
        self = dictionary.mapValues { $0.asValue }
    }

    /// Access wrapped `ValueCodable` types directly. Note that this does not
    /// distinguish between values that are missing and those that can't
    /// be unwrapped to the correct type.
    public subscript<T>(wrapped key: Key) -> T? where T: ValueCodable {
        get {
            guard let value = self[key] else { return nil }
            return value.unwrapped()
        }
        set {
            self[key] = newValue?.asValue
        }
    }

    /// Remove the value for `key`, and return the unwrapped value that was removed.
    public mutating func removeUnwrappedValue<T>(forKey key: Key) -> T? where T: Devaluable {
        guard let value = removeValue(forKey: key) else { return nil }
        return value.unwrapped()
    }

    /// Update the wrapped `value` for `key`.
    public mutating func updateValue<T>(wrapped value: T, forKey key: Key) -> T? where T: ValueCodable {
        return updateValue(value.asValue, forKey: key)?.unwrapped()
    }
}

extension Array where Element == AValue {
    /// Init from `array` with the values wrapped in `AValue`.
    public init(wrapping array: [Valuable]) {
        self = array.map { $0.asValue }
    }

    /// Append the wrapped `newElement` to the end of the array.
    public mutating func append(wrapped newElement: Valuable) {
        append(newElement.asValue)
    }

    /// Insert the wrapped `newElement` at index `i`.
    public mutating func insert(wrapped newElement: Valuable, at i: Index) {
        insert(newElement.asValue, at: i)
    }

    /// Remove the element at index `i` and return it, unwrapped.
    public mutating func removeUnwrapped<T>(at i: Index) -> T? where T: Devaluable {
        return remove(at: i).unwrapped()
    }
}

// MARK: - Devaluable

/// A type that can be unwrapped from `AValue`.
public protocol Devaluable {
    /// Unwrapped from `value`, if `value` is of the correct type.
    init?(unwrapping value: AValue)
}

extension AValue {
    /// Unwrap the value.
    public func unwrapped<ValueType: Devaluable>() -> ValueType? {
        return ValueType(unwrapping: self)
    }
}

extension RawRepresentable where RawValue: Devaluable {
    public init?(unwrapping value: AValue) {
        guard let unwrappedRawValue: RawValue = value.unwrapped() else { return nil }
        self.init(rawValue: unwrappedRawValue)
    }
}

extension Array: Devaluable where Element: Devaluable {
    /// Init by unwrapping the array `value`.
    public init?(unwrapping value: AValue) {
        guard let array = value.arrayValue else { return nil }
        guard let unwrapped: [Element] = (try? array.map { element in
            guard let unwrappedElement: Element = element.unwrapped() else { throw AValue.ValueError() }
            return unwrappedElement
            }) else { return nil }
        self = unwrapped
    }
}

extension Dictionary where Key == String, Value: Devaluable {
    /// Init by unwrapping the dictionary `value`.
    public init?(unwrapping value: AValue) {
        guard let dictionary = value.dictionaryValue else { return nil }

        guard let converted: [Key: Value] = (try? dictionary.mapValues { wrappedValue in
            guard let unwrappedValue: Value = wrappedValue.unwrapped() else { throw AValue.ValueError() }
            return unwrappedValue
            }) else { return nil }

        self = converted
    }
}

extension Dictionary: Devaluable where Key: StringRepresentable, Value: Devaluable { }

extension Data {
    /// Init from an array of bytes each wrapped in `AValue`.
    /// Fails (returns `nil`) if any of the elements is not an integer value
    /// in the appropriate range.
    public init?(byteValues: [AValue]) {
        let byteMaxValue = Integer(UInt8.max)
        guard let bytes: [UInt8] = (try? byteValues.map { element in
            guard let int = element.integerValue else { throw AValue.ValueError() }
            guard int >= 0 && int <= byteMaxValue else { throw AValue.ValueError() }
            return UInt8(int)
        }) else { return nil }
        self.init(bytes: bytes)
    }

    /// Unwrap `value` that is either a data value, or an array of bytes.
    /// Fails (returns `nil`) if `value` is neither of these.
    public init?(dataOrByteArray value: AValue) {
        if let data = value.dataValue {
            self = data
        } else if let array = value.arrayValue {
            self.init(byteValues: array)
        } else {
            return nil
        }
    }
}

// MARK: - CodedAsValue

/// As `ValueCodable`, but with a default implementation of `Codable`
/// provided by wrapping as `AValue`. Simply declare both `CodedAsValue`
/// and `Codable`.
public protocol CodedAsValue: ValueCodable { }

public extension CodedAsValue {
    public init(from decoder: Decoder) throws {
        let value = try AValue(from: decoder)
        guard let unwrapped = Self(unwrapping: value) else {
            throw AValue.ValueError()
        }
        self = unwrapped
    }

    public func encode(to encoder: Encoder) throws {
        try asValue.encode(to: encoder)
    }
}
