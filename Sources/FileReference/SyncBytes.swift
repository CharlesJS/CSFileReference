//
//  SyncBytes.swift
//  CSFileReference
//
//  Created by Charles Srstka on 11/28/24.
//

public final class SyncBytes: Collection, @unchecked Sendable {
    private let buffer: UnsafeRawBufferPointer

    public var startIndex: Int { 0 }
    public var endIndex: Int { self.buffer.count }

    internal init(capacity: Int, _ closure: (UnsafeMutableRawBufferPointer) async throws -> Int) async throws {
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: capacity, alignment: 1)

        do {
            let count = try await closure(buffer)
            self.buffer = UnsafeRawBufferPointer(rebasing: buffer.prefix(count))
        } catch {
            buffer.deallocate()
            throw error
        }
    }

    public subscript(position: Int) -> UInt8 { self.buffer[position] }
    public func index(after i: Int) -> Int { i + 1 }

    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try body(self.buffer)
    }

    public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<UInt8>) throws -> R) rethrows -> R? {
        try self.buffer.withMemoryRebound(to: UInt8.self) { try body($0) }
    }
}
