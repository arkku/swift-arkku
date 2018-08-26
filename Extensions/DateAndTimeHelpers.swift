//
// DateAndTimeHelpers.swift
//
// Copyright © 2016 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

// MARK: - Time Zones

public extension TimeZone {
    /// The Universal Coordinated Time zone (formerly known as GMT).
    public static let utc = TimeZone(secondsFromGMT: 0)!
}

// MARK: - ISO Standard Dates

public extension DateFormatter {

    /// Return a new ISO-8601 date formatter.
    public static func makeISO8601Formatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .utc
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.isLenient = true
        return formatter
    }

    /// A shared ISO8601 date formatter (e.g., "2016-09-03T10:20:30.123Z").
    public static let iso8601Formatter: DateFormatter = makeISO8601Formatter()

}

public extension Date {
    /// Attempt to `dateString` in ISO-8601 format.
    public init?(iso8601String dateString: String) {
        let formatter = DateFormatter.iso8601Formatter
        guard let date = formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) else {
            return nil
        }
        self = date
    }

    /// Return this date as an ISO-8601 string.
    public func iso8601String() -> String {
        return DateFormatter.iso8601Formatter.string(from: self)
    }
}

// MARK: - Calendar

public extension Calendar {
    /// A gregorian calendar with UTC as `timeZone`.
    public static func gregorianUTC() -> Calendar {
        return Calendar(identifier: .gregorian).utc()
    }

    /// The calendar with `timeZone` set to UTC.
    public func utc() -> Calendar {
        guard timeZone != .utc else { return self }
        var calendar = self
        calendar.timeZone = .utc
        return calendar
    }
}

// MARK: - Date Accessors

public extension Date {
    /// The age of someone born on this date, in full years.
    public func ageInYears(usingCalendar calendar: Calendar = Calendar(identifier: .gregorian)) -> Int {
        return calendar.dateComponents([.year], from: self, to: Date()).year!
    }

    /// The date of the midnight before this date, using UTC.
    public func utcMidnightBefore() -> Date {
        return midnightBefore(usingCalendar: .gregorianUTC())
    }

    /// The date of the midnight before this date, using UTC.
    public func utcNoonOfTheDay() -> Date {
        return noonOfTheDay(usingCalendar: .gregorianUTC())
    }

    /// The date of the midnight before this date.
    public func midnightBefore(usingCalendar calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        return calendar.date(bySettingHour: 0, minute: 0, second: 0, of: self, direction: .backward)!
    }

    /// The date of noon on the same day as this date.
    public func noonOfTheDay(usingCalendar calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
}

// MARK: - Time Interval Helpers

public extension TimeInterval {
    /// Time interval corresponding to a number of days.
    public init(days: Double) {
        self.init(days * 60 * 60 * 24)
    }

    /// Time interval corresponding to a number of hours.
    public init(hours: Double) {
        self.init(hours * 60 * 60)
    }

    /// Time interval corresponding to a number of minutes.
    public init(minutes: Double) {
        self.init(minutes * 60)
    }

    /// An interval of a number of minutes.
    public static func minutes(_ minutes: Double) -> TimeInterval {
        return 60 * minutes as TimeInterval
    }

    /// An interval of a number of hours.
    public static func hours(_ hours: Double) -> TimeInterval {
        return 60 * 60 * hours as TimeInterval
    }

    /// An interval of a number of hours.
    public static func days(_ days: Double) -> TimeInterval {
        return 24 * 60 * 60 * days as TimeInterval
    }
}
