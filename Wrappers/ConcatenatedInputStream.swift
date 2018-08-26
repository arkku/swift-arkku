//
// ConcatenatedInputStream.swift
//
// Introduces the `InputStream` subclass `ConcatenatedInputStream`, which
// reads multiple different streams sequentially. This allows things such as
// reading a `Data` prefix and/or suffix around a file stream, or reading
// multiple files and/or URLs as though they were concatenated.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation

/// A wrapper for reading multiple `InputStream`'s sequentially. This allows
/// mixing multiple sources, such as `Data` and files, in a single stream.
public class ConcatenatedInputStream: InputStream, ExpressibleByArrayLiteral {
    /// Prepare a wrapper stream concatenating `streams`.
    public init(of streams: [InputStream]) {
        self.streams = streams.reversed()
        super.init(data: Data())
    }

    /// Prepare a wrapper stream concatenating `data`.
    public init(of data: [Data]) {
        self.streams = data.reversed().map { InputStream(data: $0) }
        super.init(data: Data())
    }

    public convenience required init(arrayLiteral elements: InputStream...) {
        self.init(of: elements)
    }

    override public var streamStatus: Stream.Status {
        guard let status = streams.last?.streamStatus else { return .closed }
        switch status {
        case .atEnd, .closed:
            if nextStream() {
                return streams.last?.streamStatus ?? status
            }
        default: break
        }
        return status
    }

    override public var streamError: Error? {
        guard let stream = streams.last else { return super.streamError }
        return stream.streamError
    }

    override public var hasBytesAvailable: Bool {
        switch streams.count {
        case 0: return false
        case 1: return streams[0].hasBytesAvailable
        default: return true
        }
    }

    override public func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        guard let stream = streams.last else { return false }
        return stream.getBuffer(buffer, length: len)
    }

    override public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        guard let stream = streams.last else { return super.read(buffer, maxLength: len) }
        switch stream.streamStatus {
        case .atEnd, .closed:
            if nextStream() {
                return read(buffer, maxLength: len)
            }
            break
        default:
            break
        }
        let result = stream.read(buffer, maxLength: len)
        guard result >= 0 else { return result }
        if result < len && stream.streamStatus == .atEnd {
            if nextStream() {
                let nextResult = read(buffer.advanced(by: result), maxLength: len - result)
                if nextResult >= 0 {
                    return result + nextResult
                }
            }
        }
        return result
    }

    override public func close() {
        while nextStream() { }
        streams.last?.close()
    }

    override public func open() {
        guard let stream = streams.last else { return }
        switch stream.streamStatus {
        case .open, .opening:
            return
        default:
            stream.open()
        }
    }

    /// The other streams prefixing this one.
    private var streams: [InputStream]

    /// Advance to the next stream.
    private func nextStream() -> Bool {
        guard streams.count > 1 else { return false }
        let stream = streams.removeLast()
        if stream.streamStatus != .closed {
            stream.close()
        }
        open()
        return true
    }
}
