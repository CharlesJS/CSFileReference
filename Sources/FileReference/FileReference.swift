public protocol FileReference: Sendable {
    var size: UInt64 { get }

    func getData(in range: Range<UInt64>) async throws -> SyncBytes
    func getBytes(_ buffer: UnsafeMutableRawBufferPointer, in range: Range<UInt64>) async throws -> Int
    func getAsyncBytes(in range: Range<UInt64>) throws -> AsyncBytes<Self>

    mutating func close() throws
}

public extension FileReference {
    func getData(in range: Range<UInt64>) async throws -> SyncBytes {
        try await SyncBytes(capacity: range.count) {
            try await self.getBytes($0, in: range)
        }
    }

    func getAsyncBytes(in range: Range<UInt64>) throws -> AsyncBytes<Self> {
        try AsyncBytes(self, range: range)
    }
}
