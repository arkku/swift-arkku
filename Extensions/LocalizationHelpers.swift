//
// LocalizationHelpers.swift
// Requires: `UnicodeHelpers.swift`, `DateAndTimeHelpers.swift`
//
// Copyright © 2016 Kimmo Kulovesi, https://github.com/arkku/
//

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit

/// Is the application right to left?
public var isRightToLeft = (NSApplication.shared.userInterfaceLayoutDirection == .rightToLeft)
#elseif canImport(UIKit)
/// Is the application right to left?
public var isRightToLeft = (UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft)
#endif

public extension String {
    /// The string prefixed with the natural direction mark for the app's
    /// language.
    ///
    /// This is intended to be used on strings that may potentially begin with a
    /// foreign language string (e.g., if the string starts with an Arabic name
    /// while the app and the rest of the string is in English).
    var forcedToNaturalDirection: String {
        return String.naturalDirectionMark.appending(self)
    }

    /// The natural direction mark (left-to-right or right-to-left) for the
    /// app's language.
    static var naturalDirectionMark: String {
        return isRightToLeft ? .rightToLeftMark : .leftToRightMark
    }
}

public extension NSTextAlignment {
    /// The reverse of natural alignment (i.e., right for left-to-right languages).
    static var unnatural: NSTextAlignment {
        return isRightToLeft ? .left : .right
    }

    /// The natural alignment of the language (not necessarily of the text).
    static var forcedNatural: NSTextAlignment {
        return isRightToLeft ? .right : left
    }
}

// MARK: - Layout Direction

public extension CGRect {
    /// The leading edge X coordinate.
    var leadingX: CGFloat {
        return isRightToLeft ? maxX : minX
    }

    /// The trailing edge X coordinate.
    var trailingX: CGFloat {
        return isRightToLeft ? minX : maxX
    }

    /// The leading edge X coordinate with `margin` offset (outset).
    func leadingX(offsetBy margin: CGFloat) -> CGFloat {
        return isRightToLeft ? (maxX + margin) : (minX - margin)
    }

    /// The trailing edge X coordinate with `margin` offset (outset).
    func trailingX(offsetBy margin: CGFloat) -> CGFloat {
        return isRightToLeft ? (minX - margin) : (maxX + margin)
    }

    /// The leading edge X coordinate with `margin` inset.
    func leadingX(insetBy margin: CGFloat) -> CGFloat {
        return isRightToLeft ? (maxX - margin) : (minX + margin)
    }

    /// The trailing edge X coordinate with `margin` inset.
    func trailingX(insetBy margin: CGFloat) -> CGFloat {
        return isRightToLeft ? (minX + margin) : (maxX - margin)
    }

    /// Move `origin.x` so that the frame's leading edge follows the trailing edge of
    /// `sibling` by a margin of `dx`.
    mutating func move(after sibling: CGRect, margin dx: CGFloat = 0) {
        origin.x = isRightToLeft ? (sibling.minX - width - dx) : (sibling.maxX + dx)
    }

    /// Move `origin.x` so that the frame's trailing edge precedes the leading edge of
    /// `sibling` by a margin of `dx`.
    mutating func move(before sibling: CGRect, margin dx: CGFloat = 0) {
        origin.x = isRightToLeft ? (sibling.maxX + dx) : (sibling.minX - width - dx)
    }

    /// Move `origin.x` so that the frame's trailing edge precedes the trailing edge
    /// of `parent` _in its coordinates_ by a margin of `dx`.
    mutating func move(insideTrailingEdgeOf parent: CGRect, margin dx: CGFloat = 0) {
        origin.x = isRightToLeft ? dx : (parent.width - width - dx)
    }

    /// Move `origin.x` so that the frame's leading edge follows the leading edge
    /// of `parent` _in its coordinates_ by a margin of `dx`.
    mutating func move(insideLeadingEdgeOf parent: CGRect, margin dx: CGFloat = 0) {
        origin.x = isRightToLeft ? (parent.width - width - dx) : dx
    }

    /// Move `origin.x` so that the frame's leading edge is aligned with that of
    /// `sibling`, adjusted forward by `dx`.
    mutating func move(alignedWithLeadingEdgeOf sibling: CGRect, margin dx: CGFloat = 0) {
        origin.x = isRightToLeft ? (sibling.maxX - width - dx) : (sibling.minX + dx)
    }

    /// Move `origin.x` so that the frame's trailing edge is aligned with that of
    /// `sibling`, adjusted backward by `dx`.
    mutating func move(alignedWithTrailingEdgeOf sibling: CGRect, margin dx: CGFloat = 0) {
        origin.x = isRightToLeft ? (sibling.minX + dx) : (sibling.maxX - width - dx)
    }

    /// Move `origin.x` towards the trailing edge by `dx`.
    mutating func move(forward dx: CGFloat) {
        origin.x += dx * (isRightToLeft ? -1 : 1)
    }

    /// Move `origin.x` towards the leading edge by `dx`.
    mutating func move(backward dx: CGFloat) {
        origin.x += dx * (isRightToLeft ? 1 : -1)
    }
}

public extension CGPoint {
    /// The point moved towards the trailing edge by `dx`.
    func moved(forward dx: CGFloat) -> CGPoint {
        return isRightToLeft ? CGPoint(x: x - dx, y: y) : CGPoint(x: x + dx, y: y)
    }

    /// Move the point towards the trailing edge by `dx`.
    mutating func move(forward dx: CGFloat) {
        x += dx * (isRightToLeft ? -1 : 1)
    }

    /// The point moved towards the leading edge by `dx`.
    func moved(backward dx: CGFloat) -> CGPoint {
        return isRightToLeft ? CGPoint(x: x + dx, y: y) : CGPoint(x: x - dx, y: y)
    }

    /// Move the point towards the leading edge by `dx`.
    mutating func move(backward dx: CGFloat) {
        x += dx * (isRightToLeft ? 1 : -1)
    }
}

public extension CGRectEdge {
    /// The leading X edge according to UI direction.
    static var leadingXEdge: CGRectEdge {
        return isRightToLeft ? .maxXEdge : minXEdge
    }

    /// The trailing X edge according to UI direction.
    static var trailingXEdge: CGRectEdge {
        return isRightToLeft ? .minXEdge : maxXEdge
    }
}

// MARK: - Locales

public extension Locale {
    /// The locale for the app's current language. This matches the language of
    /// translated strings, whereas `Locale.current` matches the user's
    /// preferences independent of language.
    static let ofAppLanguage: Locale = {
        guard let languageID = Bundle.main.preferredLocalizations.first else {
            return Locale.current
        }
        return Locale(identifier: languageID)
    }()
}


// MARK: - Formatting Numbers

public extension NumberFormatter {
    /// Make a new decimal `NumberFormatter` for the app's current language.
    /// The formatter will have `numberStyle` `.decimal`.
    static func makeForAppLanguage() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.allowsFloats = true
        formatter.locale = .ofAppLanguage
        return formatter
    }

    /// A shared default formatter as returned by `makeNumberFormatterForAppLanguage()`.
    static let appLanguageDefault = NumberFormatter.makeForAppLanguage()
}

public extension SignedInteger {
    /// A localized decimal representation of the integer.
    func localizedString() -> String {
        return NumberFormatter.appLanguageDefault.string(from: NSNumber(value: Int64(self))) ?? description
    }
}

public extension UnsignedInteger {
    /// A localized decimal representation of the integer.
    func localizedString() -> String {
        return NumberFormatter.appLanguageDefault.string(from: NSNumber(value: UInt64(self))) ?? description
    }
}

public extension NSNumber {
    /// A localized representation of the number with a maximum of `precision` decimal places.
    func localizedString(maxDecimals precision: Int, numberStyle: NumberFormatter.Style = .decimal) -> String {
        let formatter = NumberFormatter.makeForAppLanguage()
        formatter.numberStyle = numberStyle
        formatter.maximumFractionDigits = precision
        return formatter.string(from: self) ?? description
    }
}

public extension Float {
    /// A localized representation of the number with a maximum of `precision` decimal places.
    func localizedString(maxDecimals precision: Int, numberStyle: NumberFormatter.Style = .decimal) -> String {
        return NSNumber(value: self).localizedString(maxDecimals: precision, numberStyle: numberStyle)
    }
}

public extension Double {
    /// A localized representation of the number with a maximum of `precision` decimal places.
    func localizedString(maxDecimals precision: Int, numberStyle: NumberFormatter.Style = .decimal) -> String {
        return NSNumber(value: self).localizedString(maxDecimals: precision, numberStyle: numberStyle)
    }
}

// MARK: - Formatting Dates

public extension DateFormatter {
    /// Make a new `DateFormatter` for the app's current language.
    static func makeForAppLanguage() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .ofAppLanguage
        return formatter
    }

    /// A shared formatter for short time in the app's current language.
    static let appLanguageShortTime: DateFormatter = {
        let formatter = DateFormatter.makeForAppLanguage()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    /// A shared formatter for short date in the app's current language.
    static let appLanguageShortDate: DateFormatter = {
        let formatter = DateFormatter.makeForAppLanguage()
        formatter.timeStyle = .none
        formatter.dateStyle = .short
        return formatter
    }()

    /// A shared formatter for medium date in the app's current language.
    static let appLanguageMediumDate: DateFormatter = {
        let formatter = DateFormatter.makeForAppLanguage()
        formatter.timeStyle = .none
        formatter.dateStyle = .medium
        return formatter
    }()

    /// A shared formatter for short time in the app's current language.
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    /// A shared formatter for short date in the app's current language.
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .none
        formatter.dateStyle = .short
        return formatter
    }()

    /// A shared formatter for medium date in the app's current language.
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .none
        formatter.dateStyle = .medium
        return formatter
    }()
}

public extension Date {
    /// A short localized representation of the time (typically hours and minutes) in
    /// the app's current language.
    func localizedShortTimeString() -> String {
        return DateFormatter.appLanguageShortTime.string(from: self)
    }

    /// A short localized representation of the date (without time) in the app's
    /// current language.
    func localizedShortString() -> String {
        return DateFormatter.appLanguageShortDate.string(from: self)
    }

    /// A localized representation of the date (without time) in the app's current
    /// language.
    func localizedString() -> String {
        return DateFormatter.appLanguageMediumDate.string(from: self)
    }

    /// A short localized representation of the time (typically hours and minutes) in
    /// the app's current language.
    func shortTimeString() -> String {
        return DateFormatter.shortTime.string(from: self)
    }

    /// A short localized representation of the date (without time) in the app's
    /// current language.
    func shortString() -> String {
        return DateFormatter.shortDate.string(from: self)
    }

    /// A localized representation of the date (without time) in the app's current
    /// language.
    func mediumString() -> String {
        return DateFormatter.mediumDate.string(from: self)
    }
}
