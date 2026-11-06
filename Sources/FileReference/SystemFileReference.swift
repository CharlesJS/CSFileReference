//
//  FileReference.swift
//  CSFileReference
//
//  Created by Charles Srstka on 11/28/24.
//

import SyncPolyfill

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

#if Foundation
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

@available(macOS 11.0, iOS 14.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
public final class SystemFileReference: SyncFileReference {
    private let mutex: Mutex<(fd: FileDescriptor, isClosed: Bool)>
    private let closeWhenDone: Bool
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

#if Foundation
    public convenience init(url: URL) throws {
        guard url.isFileURL else {
#if canImport(Darwin)
            throw CocoaError(.fileReadUnsupportedScheme, userInfo: [NSURLErrorKey : url])
#else
            throw CocoaError(.fileReadUnsupportedScheme, userInfo: ["NSURL" : url])
#endif
        }

        guard #available(macOS 13.0, iOS 16.0, macCatalyst 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *) else {
            try self.init(path: FilePath(url.path))
            return
        }

        try self.init(path: FilePath(url.path(percentEncoded: false)))
    }
#endif

    deinit {
        if self.closeWhenDone {
            self.mutex.withLock { try? $0.fd.close() }
        }
    }

    public func syncGetBytes(_ buffer: UnsafeMutableRawBufferPointer, in range: Range<UInt64>) throws -> Int {
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
