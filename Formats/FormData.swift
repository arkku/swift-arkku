//
// FormData.swift
//
// Helpers for constructing a web form (`multipart/form-data`).
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

/// A multipart web form (`multipart/form-data`).
public struct FormData: CustomDebugStringConvertible {
    /// The boundary that must not occur as part of any key or value in the form.
    public let boundary: Data

    /// The `Content-Type` of this form.
    public let contentType: String

    /// The header at the start of the form.
    private(set) public var header = Data()

    /// The footer at the end of the form.
    private(set) public var footer: Data

    /// The form body to be sent as a HTTP request. This is just `header`
    /// followed by `footer`.
    public var body: Data {
        var body = header
        body.append(footer)
        return body
    }

    private let keyPrefix: Data
    private let keySuffix: Data
    private let valueSuffix: Data

    /// Prepare a form with the given `boundary`.
    public init(boundary: Data) {
        self.boundary = boundary

        let boundaryString = String(data: boundary, encoding: .utf8)!
        self.contentType = "multipart/form-data; boundary=\(boundaryString)"

        let dashes = "--".data(using: .utf8)!
        let crlf = "\r\n".data(using: .utf8)!

        var prefix = dashes
        prefix.append(boundary)
        prefix.append(crlf)
        prefix.append("Content-Disposition: form-data; name=\"".data(using: .utf8)!)
        self.keyPrefix = prefix
        self.keySuffix = "\r\n\r\n".data(using: .utf8)!

        self.valueSuffix = crlf

        var footer = crlf
        footer.append(dashes)
        footer.append(boundary)
        footer.append(dashes)
        self.footer = footer
    }

    /// Prepare a form with the given `boundary`.
    public init?(boundary: String) {
        guard let boundaryData = boundary.data(using: .utf8) else { return nil }
        self.init(boundary: boundaryData)
    }

    /// Prepare a form with a random boundary that is not found in `data`.
    public init(randomBoundaryFor data: Data) {
        let boundary: Data = {
            var boundary: Data
            repeat {
                boundary = "\(UUID().uuidString)-boundary".data(using: .utf8)!
            } while data.range(of: boundary) != nil
            return boundary
        }()
        self.init(boundary: boundary)
    }

    /// Append `value` for `key` into the form.
    ///
    /// Returns `true` on success, `false` on failure (e.g., either of key or
    /// value aren't valid UTF-8 or contain `boundary`).
    @discardableResult
    public mutating func append(value: String, forKey key: String) -> Bool {
        guard let valueData = value.data(using: .utf8) else { return false }
        return append(value: valueData, forKey: key)
    }

    /// Append `value` for `key` into the form.
    ///
    /// Returns `true` on success, `false` on failure (e.g., the key is not a
    /// valid UTF-8 string, or either the key or the value contain `boundary`).
    @discardableResult
    public mutating func append(value: Data, forKey key: String, valueFilename filename: String? = nil, valueContentType contentType: String? = nil, checkForBoundaryInValue: Bool = true) -> Bool {
        guard append(keyOnly: key, filename: filename, contentType: contentType) else { return false }
        guard !checkForBoundaryInValue || value.range(of: boundary) == nil else { return false }
        header.append(value)
        return true
    }

    /// Append `key` without a value. This is intended to be used when the form
    /// contains a large value that is to be streamed from a file after `header`.
    ///
    /// Returns `true` on success, `false` on failure (e.g., the key is not a
    /// valid UTF-8 string, or it contains `boundary`).
    @discardableResult
    public mutating func append(keyOnly key: String, filename: String? = nil, contentType: String? = nil) -> Bool {
        guard let keyData = key.data(using: .utf8) else { return false }
        guard keyData.range(of: boundary) == nil else { return false }
        var suffix = "\""
        if let filename = filename {
            suffix.append("; filename=\"\(filename)\"")
        }
        if let contentType = contentType {
            suffix.append("\r\nContent-Type: \(contentType)")
        }
        guard let suffixData = suffix.data(using: .utf8), suffixData.range(of: boundary) == nil else { return false }
        if header.isEmpty {
            // This is the first key, so let's put the suffix for the last value
            // into the footer.
            var newFooter = valueSuffix
            newFooter.append(footer)
            footer = newFooter
        } else {
            // There is a previous value in header, let's add the suffix for it.
            header.append(valueSuffix)
        }
        header.append(keyPrefix)
        header.append(keyData)
        header.append(suffixData)
        header.append(keySuffix)
        return true
    }

    /// Make a `URLRequest` for posting this form to `url`.
    public func makeRequest(url: URL, method: String = "POST") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    public var debugDescription: String {
        let bodyData = body
        if let asString = String(data: bodyData, encoding: .utf8) {
            return asString
        } else {
            return "FormData(\(bodyData.count) bytes)"
        }
    }
}
