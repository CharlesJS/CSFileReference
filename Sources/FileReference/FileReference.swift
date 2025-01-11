public protocol FileReference: Sendable {
    associatedtype SliceType: FileReference = FileReferenceSlice<Self>

    var size: UInt64 { get }

    func getData(in range: Range<UInt64>) async throws -> SyncBytes
    func getBytes(_ buffer: UnsafeMutableRawBufferPointer, in range: Range<UInt64>) async throws -> Int
    func getAsyncBytes(in range: Range<UInt64>) throws -> AsyncBytes<Self>

    func getSlice(in range: Range<UInt64>) -> SliceType

    mutating func close() throws
}

public extension FileReference {
    func getData(at offset: some BinaryInteger, length: some BinaryInteger) async throws -> SyncBytes {
        try await self.getData(in: UInt64(offset)..<(UInt64(offset) + UInt64(length)))
    }

    func getData(in range: Range<UInt64>) async throws -> SyncBytes {
        try await SyncBytes(capacity: range.count) {
            try await self.getBytes($0, in: range)
        }
    }

    func getAsyncBytes(at offset: some BinaryInteger, length: some BinaryInteger) throws -> AsyncBytes<Self> {
        try self.getAsyncBytes(in: UInt64(offset)..<(UInt64(offset) + UInt64(length)))
    }

    func getAsyncBytes(in range: Range<UInt64>) throws -> AsyncBytes<Self> {
        try AsyncBytes(self, range: range)
    }
}

public extension FileReference where SliceType == FileReferenceSlice<Self> {
    func getSlice(in range: Range<UInt64>) -> SliceType {
        FileReferenceSlice(parent: self, range: range, isClosed: false)
    }
}
