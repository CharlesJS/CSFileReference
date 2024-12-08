//
//  AsyncBytes.swift
//
//
//  Created by Charles Srstka on 6/2/24.
//

public struct AsyncBytes<FileReferenceType: FileReference>: Sendable, AsyncSequence {
    public typealias Element = UInt8
    private let fileReference: FileReferenceType
    private let range: Range<UInt64>
    private let capacity: Int

    internal init(_ fileReference: FileReferenceType, range: Range<UInt64>, capacity: Int = 16384) throws {
        self.fileReference = fileReference
        self.range = range
        self.capacity = capacity
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(fileReference: self.fileReference, range: self.range, capacity: self.capacity)
    }

    // Loosely based on AsyncBufferedByteIterator from https://github.com/apple/swift-async-algorithms
    // Modified for use in CSFileReference by Charles Srstka, 2024.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private let fileReference: FileReferenceType
        private var range: Range<UInt64>
        private let capacity: Int

        private let buffer: UnsafeMutableRawBufferPointer
        private let bufferDeallocator: BufferDeallocator

        @usableFromInline internal var nextPointer: UnsafeRawPointer
        @usableFromInline internal var endPointer: UnsafeRawPointer

        internal var isDone = false

        fileprivate init(fileReference: FileReferenceType, range: Range<UInt64>, capacity: Int) {
            precondition(capacity > 0)

            self.fileReference = fileReference
            self.range = range
            self.capacity = capacity

            let buffer = UnsafeMutableRawBufferPointer.allocate(
                byteCount: capacity,
                alignment: MemoryLayout<AnyObject>.alignment
            )

            self.buffer = buffer
            self.bufferDeallocator = BufferDeallocator(buffer: buffer)
            self.nextPointer = UnsafeRawPointer(buffer.baseAddress!)
            self.endPointer = nextPointer
        }

        private final class BufferDeallocator {
            private let buffer: UnsafeMutableRawBufferPointer

            init(buffer: UnsafeMutableRawBufferPointer) {
                self.buffer = buffer
            }

            deinit {
                self.buffer.deallocate()
            }
        }

        @usableFromInline
        internal mutating func reloadBuffer() async throws -> Bool {
            if self.isDone { return false }
            try Task.checkCancellation()

            do {
                let lowerBound = self.range.lowerBound
                let upperBound = Swift.min(lowerBound + UInt64(self.capacity), self.range.upperBound)
                let bytesRead = try await self.fileReference.getBytes(buffer, in: lowerBound..<upperBound)
                let newLowerBound = Swift.min(lowerBound + UInt64(bytesRead), self.range.upperBound)
                self.range = newLowerBound..<self.range.upperBound

                if bytesRead == 0 {
                    self.isDone = true
                    self.nextPointer = self.endPointer
                    return false
                }

                self.nextPointer = UnsafeRawPointer(self.buffer.baseAddress!)
                self.endPointer = self.nextPointer + bytesRead

                return true
            } catch {
                self.isDone = true
                self.nextPointer = self.endPointer
                throw error
            }
        }

        @inlinable @inline(__always)
        public mutating func next() async throws -> UInt8? {
            if _fastPath(self.nextPointer != self.endPointer) {
                let byte = nextPointer.load(fromByteOffset: 0, as: UInt8.self)
                self.nextPointer += 1
                return byte
            }

            return try await self.reloadBuffer() ? self.next() : nil
        }

        @inlinable @inline(__always)
        public mutating func getBytes(_ buffer: UnsafeMutableRawBufferPointer) async throws -> Int {
            if _fastPath(self.nextPointer != self.endPointer) {
                let bytesToCopy = Swift.min(self.endPointer - self.nextPointer, buffer.count)

                buffer.copyMemory(from: UnsafeRawBufferPointer(start: self.nextPointer, count: bytesToCopy))

                self.nextPointer += bytesToCopy
                return bytesToCopy
            }

            return try await self.reloadBuffer() ? self.getBytes(buffer) : 0
        }
    }
}

@available(*, unavailable)
extension AsyncBytes.AsyncIterator: Sendable {}
