//
// MillisecondsDate.swift
//
// Extends `Date` with accessors and constructors for the date as
// milliseconds since 1970. This is consistent with the JSON encoder
// `dateEncodingStrategy` of `millisecondsSince1970`. The intent is
// that if the date thus encoded ends up being decoded into an integer
// or floating point value, such as when it is a member of a dynamic
// structure, these helpers make it easy to convert back to `Date`.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

public extension Date {
    /// A date with `milliseconds` since 1970.
    public init(millisecondsSince1970 milliseconds: Double) {
        self.init(timeIntervalSince1970: (milliseconds / 1000) as TimeInterval)
    }

    /// A date with `milliseconds` since 1970.
    public init(millisecondsSince1970 milliseconds: Int64) {
        self.init(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }

    /// Milliseconds since 1970.
    public var millisecondsSince1970: Double {
        return (timeIntervalSince1970 as Double) * 1000
    }

    /// Integer milliseconds since 1970.
    public var integerMillisecondsSince1970: Int64 {
        return Int64(millisecondsSince1970)
    }
}
