//
//  RawDataFileReference.swift
//  CSFileReference
//
//  Created by Charles Srstka on 11/28/24.
//

public struct RawDataFileReference: FileReference {
    public let data: ContiguousArray<UInt8>
    private var isClosed: Bool = false

    public init(data: some Collection<UInt8>) {
        self.data = ContiguousArray(data)
    }

    public var size: UInt64 { UInt64(self.data.count) }

    public func getBytes(_ buffer: UnsafeMutableRawBufferPointer, in range: Range<UInt64>) async throws -> Int {
        if self.isClosed { throw FileReferenceError.closed }

        let lowerBound = max(self.data.startIndex, self.data.index(self.data.startIndex, offsetBy: Int(range.lowerBound)))
        let upperBound = min(self.data.endIndex, self.data.index(lowerBound, offsetBy: min(range.count, buffer.count)))

        buffer.copyBytes(from: self.data[lowerBound..<upperBound])

        return self.data.distance(from: lowerBound, to: upperBound)
    }

    public mutating func close() throws { self.isClosed = true }
}
