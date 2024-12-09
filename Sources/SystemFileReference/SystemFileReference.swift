//
//  FileReference.swift
//  CSFileReference
//
//  Created by Charles Srstka on 11/28/24.
//

import FileReference
import SyncPolyfill
import System

@available(macOS 11.0, iOS 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
public final class SystemFileReference: FileReference {
    public let mutex: Mutex<(fd: FileDescriptor, isClosed: Bool)>
    public let closeWhenDone: Bool
    public let size: UInt64

    public convenience init(path: FilePath) throws {
        try self.init(fileDescriptor: try FileDescriptor.open(path, .readOnly), closeWhenDone: true)
    }

    public init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
        self.mutex = Mutex((fd: fileDescriptor, isClosed: false))
        self.closeWhenDone = closeWhenDone

        let oldOffset = try fileDescriptor.seek(offset: 0, from: .current)
        defer { _ = try? fileDescriptor.seek(offset: oldOffset, from: .start) }

        self.size = try UInt64(fileDescriptor.seek(offset: 0, from: .end))
    }

    deinit {
        if self.closeWhenDone {
            self.mutex.withLock { try? $0.fd.close() }
        }
    }

    public func getBytes(_ buffer: UnsafeMutableRawBufferPointer, in range: Range<UInt64>) async throws -> Int {
        return try self.mutex.withLock {
            if $0.isClosed { throw FileReferenceError.closed }

            return try $0.fd.read(
                fromAbsoluteOffset: Int64(range.lowerBound),
                into: UnsafeMutableRawBufferPointer(rebasing: buffer.prefix(range.count))
            )
        }
    }

    public func close() throws {
        try self.mutex.withLock {
            try $0.fd.close()
            $0.isClosed = true
        }
    }

    public func withRawDescriptorAccess<R>(_ closure: (FileDescriptor) throws -> R) rethrows -> R {
        try self.mutex.withLock {
            try closure($0.fd)
        }
    }
}
