//
// DataHexEncoding.swift
//
// Copyright © 2018 Kimmo Kulovesi. All rights reserved.
//

import Foundation

public extension Data {
    /// Encode the data into a hexadecimal string.
    func hexEncodedString() -> String {
        let digits = "0123456789abcdef".utf8.map { UInt8($0) }
        var hexBytes = [UInt8]()
        hexBytes.reserveCapacity(count * 2) // each byte is encoded into two

        for byte in self {
            hexBytes.append(digits[Int(byte >> 4)])
            hexBytes.append(digits[Int(byte & 0x0F)])
        }

        return String(bytes: hexBytes, encoding: .utf8)!
    }

    /// Interpret `hexString` as hexadecimal.
    init?(hexEncoded hexString: String) {
        let ignoredCharacters = CharacterSet.whitespacesAndNewlines

        var bytes = [UInt8]()
        bytes.reserveCapacity(hexString.count / 2)
        var hexByte = ""
        for character in hexString.unicodeScalars {
            guard !ignoredCharacters.contains(character) else { continue }
            if hexByte.isEmpty {
                hexByte = String(character)
            } else {
                hexByte.append(String(character))
                guard let byte = UInt8(hexByte, radix: 16) else { return nil }
                bytes.append(byte)
                hexByte = ""
            }
        }
        guard hexByte.isEmpty else { return nil } // odd number of nybbles
        self = Data(bytes)
    }
}
