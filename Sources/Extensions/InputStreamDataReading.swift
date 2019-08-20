//
// InputStreamDataReading.swift
//
// An extension to read all the data from an `InputStream`.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

public extension InputStream {
    /// Read all the data from the stream and return it.
    ///
    /// Note: This may be arbitrarily slow, e.g., if the stream is reading
    /// over the network.
    func readData(bufferSize: Int = 4096) throws -> Data {
        if streamStatus == .notOpen { open() }

        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        repeat {
            let bytesRead = read(buffer, maxLength: bufferSize)
            guard bytesRead >= 0 else {
                if let error = streamError { throw error }
                break
            }
            if bytesRead > 0 {
                data.append(buffer, count: bytesRead)
            }
        } while streamStatus != .atEnd

        return data
    }
}
