//
// FormDataInputStream.swift
// Requires: `FormData.swift` and `ConcatenatedInputStream.swift`
//
// This provides helpers to construct an `InputStream` from `FormData`.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

public extension FormData {
    /// Make an `InputStream` reading the `body` of this form.
    public func makeInputStream() -> InputStream {
        return ConcatenatedInputStream(of: [InputStream(data: header), InputStream(data: footer)])
    }

    /// Make an `InputStream` reading the `header` and `footer` of this form
    /// around the contents of `stream`.
    public func makeInputStream(wrappingStream stream: InputStream) -> InputStream {
        return ConcatenatedInputStream(of: [InputStream(data: header), stream, InputStream(data: footer)])
    }

    /// Make an `InputStream` reading the `header` and `footer` of this form
    /// around the contents of the file at `filePath`.
    public func makeInputStream(wrappingFileAtPath filePath: String) -> InputStream? {
        guard let payloadStream = InputStream(fileAtPath: filePath) else { return nil }
        return makeInputStream(wrappingStream: payloadStream)
    }

    /// Make an `InputStream` reading the `header` and `footer` of this form
    /// around the contents of `url`.
    public func makeInputStream(wrappingURL url: URL) -> InputStream? {
        guard let payloadStream = InputStream(url: url) else { return nil }
        return makeInputStream(wrappingStream: payloadStream)
    }
}
