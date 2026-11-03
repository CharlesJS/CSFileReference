//
//  SyncFileReference.swift
//  CSFileReference
//
//  Created by Charles Srstka on 10/26/26.
//

public protocol SyncFileReference: FileReference {
    func syncGetData(in range: Range<UInt64>) throws -> SyncBytes
    func syncGetBytes(_ buffer: UnsafeMutableRawBufferPointer, in range: Range<UInt64>) throws -> Int
}

public extension SyncFileReference {
    func getBytes(_ buffer: UnsafeMutableRawBufferPointer, in range: Range<UInt64>) async throws -> Int {
        try self.syncGetBytes(buffer, in: range)
    }

    func getData(in range: Range<UInt64>) async throws -> SyncBytes {
        try self.syncGetData(in: range)
    }

    func getSlice(in range: Range<UInt64>) -> SyncFileReferenceSlice<Self> {
        SyncFileReferenceSlice(parent: self, range: range, isClosed: false)
    }

    func syncGetData(in range: Range<UInt64>) throws -> SyncBytes {
        try SyncBytes(capacity: range.count) {
            try self.syncGetBytes($0, in: range)
        }
    }
}

