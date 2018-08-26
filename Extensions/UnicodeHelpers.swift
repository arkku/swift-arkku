//
// UnicodeHelpers.swift
//
// Copyright © 2016 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

public extension String {
    /// Does the string contain only emoji characters?
    public var containsOnlyEmoji: Bool {
        return unicodeScalars.first(where: { !$0.isEmoji && !$0.isJoiner }) == nil
    }

    /// Does the string contain emoji characters?
    public var containsEmoji: Bool {
        return unicodeScalars.first(where: { $0.isEmoji }) != nil
    }

    /// The left-to-right directional mark.
    public static let leftToRightMark = "\u{200E}"

    /// The right-to-left directional mark.
    public static let rightToLeftMark = "\u{200F}"

    /// This string prefixed by the left-to-right mark.
    public var forcedLeftToRight: String {
        return String.leftToRightMark.appending(self)
    }
    /// This string prefixed by the right-to-left mark.
    public var forcedRightToLeft: String {
        return String.rightToLeftMark.appending(self)
    }
}

public extension UnicodeScalar {
    /// Is the scalar an emoji character, or an emoji-related special character?
    public var isEmoji: Bool {
        switch value {
        case
        0x1D000...0x1F77F,          // Emoticons
        0x02100...0x027BF,          // Symbols and Dingbats
        0x0FE00...0x0FE0F,          // Variation Selectors
        0x1F900...0x1F9FF:          // More Symbols and Pictographs
            return true
        default:
            return false
        }
    }

    /// Is the scalar a zero-width joiner?
    public var isJoiner: Bool { return value == 0x0200D }
}
