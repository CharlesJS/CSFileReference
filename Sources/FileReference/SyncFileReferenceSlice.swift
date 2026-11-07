//
//  SyncFileReferenceSlice.swift
//  CSFileReference
//
//  Created by Charles Srstka on 10/26/26.
//

public struct SyncFileReferenceSlice<Parent: SyncFileReference>: SyncFileReference {
    let parent: Parent
    let range: Range<UInt64>
    private(set) var isClosed: Bool

    public var size: UInt64 { self.range.upperBound - self.range.lowerBound }

    public func syncGetBytes(_ buffer: UnsafeMutableRawBufferPointer, in range: Range<UInt64>) throws -> Int {
        guard !self.isClosed else { throw FileReferenceError.closed }

        return try self.parent.syncGetBytes(buffer, in: self.getSliceRange(for: range))
    }

    public func getSlice(in range: Range<UInt64>) -> SyncFileReferenceSlice<Parent> {
        SyncFileReferenceSlice(parent: self.parent, range: self.getSliceRange(for: range), isClosed: self.isClosed)
    }

    private func getSliceRange(for range: Range<UInt64>) -> Range<UInt64> {
        let lowerBound = self.range.lowerBound + range.lowerBound
        let upperBound = self.range.lowerBound + range.upperBound

        return (lowerBound..<upperBound).clamped(to: self.range)
    }

    public mutating func close() throws {
        self.isClosed = true
    }
}
