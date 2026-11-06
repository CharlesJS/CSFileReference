//
//  AnyFileReference.swift
//  CSFileReference
//
//  Created by Charles Srstka on 11/4/26.
//

public struct AnyFileReference: FileReference {
    private var file: any FileReference

    public init(_ file: some FileReference) {
        self.file = file
    }

    public var size: UInt64 { self.file.size }

    public func getData(in range: Range<UInt64>) async throws -> SyncBytes { try await self.file.getData(in: range) }

    public func getBytes(_ buffer: UnsafeMutableRawBufferPointer, in range: Range<UInt64>) async throws -> Int {
        try await self.file.getBytes(buffer, in: range)
    }

    public mutating func close() throws { try self.file.close() }
}
