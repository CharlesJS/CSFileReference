//
//  LineSequence.swift
//  CSFileReference
//
//  Created by Charles Srstka on 3/21/26.
//
//  Only relevant on Linux; on Apple platforms we use the built in `AsyncLineSequence`.
//  Included so `AsyncBytes` can support `lines` on Linux.
//  If swift-foundation ever gets `AsyncLineSequence`, we can delete this file and just use that.

#if !canImport(Darwin)

extension AsyncBytes {
    struct LineSequence: AsyncSequence, Sendable {
        struct AsyncIterator: AsyncIteratorProtocol {
            private var iterator: AsyncBytes.AsyncIterator
            private var buffer: ContiguousArray<UInt8>
            private var cursor: ContiguousArray<UInt8>.Index

            init(bytes: AsyncBytes) {
                let bufferSize = 10 * 1024

                self.iterator = bytes.makeAsyncIterator()
                self.buffer = []
                self.buffer.reserveCapacity(bufferSize)
                self.cursor = self.buffer.startIndex
            }

            mutating func next() async throws -> String? {
                var chars: ContiguousArray<UInt8> = []
                var slice = self.buffer[self.cursor...]

                if slice.isEmpty {
                    try await self.refreshBuffer()
                    slice = self.buffer[...]
                }

                while !slice.isEmpty {
                    if let nlIndex = slice.firstIndex(where: { $0 == 0x0a || $0 == 0x0d }) {
                        chars.append(contentsOf: slice.prefix(upTo: nlIndex))
                        self.cursor = nlIndex + 1
                        slice = buffer[self.cursor...]

                        if !chars.isEmpty {
                            return String(decoding: chars, as: UTF8.self)
                        }
                    } else {
                        chars.append(contentsOf: slice)
                        try await self.refreshBuffer()
                        slice = self.buffer[...]
                    }
                }

                return chars.isEmpty ? nil : String(decoding: chars, as: Unicode.UTF8.self)
            }

            private mutating func refreshBuffer() async throws {
                self.buffer.removeAll(keepingCapacity: true)
                self.cursor = self.buffer.startIndex

                let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: self.buffer.capacity, alignment: 1)
                defer { buf.deallocate() }

                let len = try await self.iterator.getBytes(buf)

                self.buffer.append(contentsOf: buf.prefix(len))
            }
        }

        let bytes: AsyncBytes

        func makeAsyncIterator() -> AsyncIterator {
            Self.AsyncIterator(bytes: self.bytes)
        }
    }
}

#endif
