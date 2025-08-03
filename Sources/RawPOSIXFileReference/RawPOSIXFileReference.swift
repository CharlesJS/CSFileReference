//
//  RawPOSIXFileReference.swift
//  CSFileReference
//
//  Created by Charles Srstka on 11/28/24.
//

#if canImport(Darwin)
import Darwin
import SyncPolyfill
#elseif canImport(Glibc)
import Glibc
import Synchronization
#endif

#if canImport(unistd)
import unistd
#endif

#if canImport(Darwin) || canImport(Glibc)
import CSErrors
import FileReference

public final class RawPOSIXFileReference: FileReference {
    private let mutex: Mutex<(fd: Int32, isClosed: Bool)>
    private let closeWhenDone: Bool
    public let size: UInt64

    public convenience init(path: String) throws {
        let fd = try callPOSIXFunction(expect: .nonNegative) { open(path, O_RDONLY) }
        try self.init(fileDescriptor: fd, closeWhenDone: true)
    }

    public init(fileDescriptor fd: Int32, closeWhenDone: Bool) throws {
        self.mutex = Mutex((fd: fd, isClosed: false))
        self.closeWhenDone = closeWhenDone

        let oldOffset = try callPOSIXFunction(expect: .nonNegative) { lseek(fd, 0, SEEK_CUR) }
        defer { lseek(fd, oldOffset, SEEK_SET) }

        let size = try callPOSIXFunction(expect: .nonNegative) { lseek(fd, 0, SEEK_END) }
        self.size = UInt64(size)
    }

    deinit {
        if self.closeWhenDone {
            _ = self.mutex.withLock { unistd.close($0.fd) }
        }
    }

    public func getBytes(_ buffer: UnsafeMutableRawBufferPointer, in range: Range<UInt64>) async throws -> Int {
        return try self.mutex.withLock {
            if $0.isClosed { throw FileReferenceError.closed }
            let fd = $0.fd

            try callPOSIXFunction(expect: .nonNegative) { lseek(fd, Int64(range.lowerBound), SEEK_SET) }
            return try callPOSIXFunction(expect: .nonNegative) {
                read(fd, buffer.baseAddress, min(buffer.count, range.count))
            }
        }
    }

    public func close() throws {
        self.mutex.withLock {
            _ = unistd.close($0.fd)
            $0.isClosed = true
        }
    }

    public func withRawDescriptorAccess<R>(_ closure: (Int32) throws -> R) rethrows -> R {
        try self.mutex.withLock {
            try closure($0.fd)
        }
    }
}
#endif
