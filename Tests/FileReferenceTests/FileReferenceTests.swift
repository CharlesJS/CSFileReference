//
//  FileReferenceTests.swift
//  CSFileReference
//
//  Created by Charles Srstka on 12/3/24.
//

import Foundation
import System
import Testing

@testable import FileReference
@testable import HTTPFileReference
@testable import RawPOSIXFileReference
@testable import SystemFileReference

struct Fixture: CustomTestStringConvertible, Identifiable, Sendable {
    let name: String
    let constructor: @Sendable () async throws -> any FileReference

    var testDescription: String { self.name }
    var id: String { self.name }
}

let fixtureURL = Bundle.module.url(forResource: "moby-ch1", withExtension: "txt", subdirectory: "Fixtures")!
let fixtureData = try! Data(contentsOf: fixtureURL)
let paddedData = Data(count: 100) + fixtureData + Data(count: 100)
let paddedRange = 100..<UInt64(fixtureData.count + 100)
let paddedURL: URL = try! {
    let url = FileManager.default.temporaryDirectory.appending(path: "com.charlessoft.CSFileReference.PaddedData")
    try paddedData.write(to: url)
    return url
}()

let fixtures = [
    Fixture(name: "Raw Data") { RawDataFileReference(data: fixtureData) },
    Fixture(name: "HTTP") {
        let mockHTTPConfig = MockURLProtocol.makeStubConfig { request in
            try MockURLProtocol.makeSuccessResponse(request: request, data: fixtureData)
        }

        return try await HTTPFileReference(url: fixtureURL, configuration: mockHTTPConfig)
    },
    Fixture(name: "POSIX File") { try RawPOSIXFileReference(path: fixtureURL.path) },
    Fixture(name: "System File") { try SystemFileReference(path: FilePath(fixtureURL.path)) },
    Fixture(name: "Raw Data Slice") { RawDataFileReference(data: paddedData).getSlice(in: paddedRange) },
    Fixture(name: "HTTP Slice") {
        let mockHTTPConfig = MockURLProtocol.makeStubConfig { request in
            try MockURLProtocol.makeSuccessResponse(request: request, data: paddedData)
        }

        return try await HTTPFileReference(url: fixtureURL, configuration: mockHTTPConfig).getSlice(in: paddedRange)
    },
    Fixture(name: "POSIX File Slice") { try RawPOSIXFileReference(path: paddedURL.path).getSlice(in: paddedRange) },
    Fixture(name: "System File Slice") { try SystemFileReference(path: FilePath(paddedURL.path)).getSlice(in: paddedRange) }

]

@Test(.serialized, arguments: fixtures) func testGetData(fixture: Fixture) async throws {
    let fileRef = try await fixture.constructor()

    // read entire file
    #expect(try await Data(fileRef.getData(in: 0..<fileRef.size)) == fixtureData)
    #expect(try await Data(fileRef.getData(at: 0, length: fileRef.size)) == fixtureData)

    // read arbitrary ranges
    #expect(try await String(bytes: fileRef.getData(in: 0x18..<0x28), encoding: .utf8) == "Call me Ishmael.")
    #expect(try await String(bytes: fileRef.getData(at: 0x18, length: 0x10), encoding: .utf8) == "Call me Ishmael.")

    #expect(try await String(bytes: fileRef.getData(in: 0x1bf6..<0x1c08), encoding: .utf8) == "like a grasshopper")
    #expect(try await String(bytes: fileRef.getData(at: 0x1bf6, length: 0x12), encoding: .utf8) == "like a grasshopper")

    #expect(try await String(bytes: fileRef.getData(in: 0x612..<0x620), encoding: .utf8) == "Circumambulate")
    #expect(try await String(bytes: fileRef.getData(at: 0x612, length: 0xe), encoding: .utf8) == "Circumambulate")

    // out of bounds reads should get trimmed
    #expect(try await Data(fileRef.getData(in: (fileRef.size - 1024)..<(fileRef.size + 100))) == fixtureData.suffix(1024))
    #expect(try await Data(fileRef.getData(at: fileRef.size - 1024, length: 1124)) == fixtureData.suffix(1024))
}

@Test(.serialized, arguments: fixtures) func testGetBytes(fixture: Fixture) async throws {
    let fileRef = try await fixture.constructor()

    // read entire file
    #expect(try await readBytes(fileRef, 0..<fileRef.size) == fixtureData)

    // read arbitrary ranges
    #expect(try await String(data: readBytes(fileRef, 0x18..<0x28), encoding: .utf8) == "Call me Ishmael.")
    #expect(try await String(data: readBytes(fileRef, 0x1bf6..<0x1c08), encoding: .utf8) == "like a grasshopper")
    #expect(try await String(data: readBytes(fileRef, 0x612..<0x620), encoding: .utf8) == "Circumambulate")

    // out of bounds reads should get trimmed
    #expect(try await readBytes(fileRef, (fileRef.size - 1024)..<(fileRef.size + 100)) == fixtureData.suffix(1024))
}

@Test(.serialized, arguments: fixtures) func testGetAsyncBytesWithOffsetAndLength(fixture: Fixture) async throws {
    func unwrap<T: FileReference>(_ fileRef: T) async throws {
        func readString(_ offset: some BinaryInteger, _ length: some BinaryInteger) async throws -> String? {
            try await withBytes(fileRef, offset: offset, length: length) {
                try await String(bytes: $0.reduce(into: []) { $0.append($1) }, encoding: .utf8)
            }
        }

        // read entire file
        try await withBytes(fileRef, offset: 0, length: fileRef.size) { bytes in
            let lines = try await bytes.lines.reduce(into: []) { $0.append($1) }
            #expect(lines.count == 184)
            #expect(lines[0] == "CHAPTER 1. Loomings.")
            #expect(lines[1] == "Call me Ishmael. Some years ago—never mind how long precisely—having")
            #expect(lines[2] == "little or no money in my purse, and nothing particular to interest me")
            #expect(lines[183] == "all, one grand hooded phantom, like a snow hill in the air.")
        }

        // read arbitrary ranges
        #expect(try await readString(0x18, 0x10) == "Call me Ishmael.")
        #expect(try await readString(0x612, 0xe) == "Circumambulate")
        try await withBytes(fileRef, offset: 0x484, length: 0x18e) { bytes in
            var lines = bytes.lines.makeAsyncIterator()
            try #expect(await lines.next() == "There now is your insular city of the Manhattoes, belted round by")
            try #expect(await lines.next() == "wharves as Indian isles by coral reefs—commerce surrounds it with her")
            try #expect(await lines.next() == "surf. Right and left, the streets take you waterward. Its extreme")
            try #expect(await lines.next() == "downtown is the battery, where that noble mole is washed by waves, and")
            try #expect(await lines.next() == "cooled by breezes, which a few hours previous were out of sight of")
            try #expect(await lines.next() == "land. Look at the crowds of water-gazers there.")
            try #expect(await lines.next() == nil)
        }

        // out of bounds reads should get trimmed
        #expect(try await fileRef.getAsyncBytes(at: fileRef.size - 1024, length: 1124).reduce(into: Data()) {
            $0.append($1)
        } == fixtureData.suffix(1024))
    }

    try await unwrap(try await fixture.constructor())
}

@Test(.serialized, arguments: fixtures) func testGetAsyncBytesWithRange(fixture: Fixture) async throws {
    func unwrap<T: FileReference>(_ fileRef: T) async throws {
        func readString(_ range: Range<UInt64>) async throws -> String? {
            try await withBytes(fileRef, range: range) {
                try await String(bytes: $0.reduce(into: []) { $0.append($1) }, encoding: .utf8)
            }
        }

        // read entire file
        try await withBytes(fileRef, range: 0..<fileRef.size) { bytes in
            let lines = try await bytes.lines.reduce(into: []) { $0.append($1) }
            #expect(lines.count == 184)
            #expect(lines[0] == "CHAPTER 1. Loomings.")
            #expect(lines[1] == "Call me Ishmael. Some years ago—never mind how long precisely—having")
            #expect(lines[2] == "little or no money in my purse, and nothing particular to interest me")
            #expect(lines[183] == "all, one grand hooded phantom, like a snow hill in the air.")
        }

        // read arbitrary ranges
        #expect(try await readString(0x18..<0x28) == "Call me Ishmael.")
        #expect(try await readString(0x612..<0x620) == "Circumambulate")
        try await withBytes(fileRef, range: 0x484..<0x612) { bytes in
            var lines = bytes.lines.makeAsyncIterator()
            try #expect(await lines.next() == "There now is your insular city of the Manhattoes, belted round by")
            try #expect(await lines.next() == "wharves as Indian isles by coral reefs—commerce surrounds it with her")
            try #expect(await lines.next() == "surf. Right and left, the streets take you waterward. Its extreme")
            try #expect(await lines.next() == "downtown is the battery, where that noble mole is washed by waves, and")
            try #expect(await lines.next() == "cooled by breezes, which a few hours previous were out of sight of")
            try #expect(await lines.next() == "land. Look at the crowds of water-gazers there.")
            try #expect(await lines.next() == nil)
        }

        // out of bounds reads should get trimmed
        #expect(try await fileRef.getAsyncBytes(in: (fileRef.size - 1024)..<(fileRef.size + 100)).reduce(into: Data()) {
            $0.append($1)
        } == fixtureData.suffix(1024))
    }

    try await unwrap(try await fixture.constructor())
}

@Test(.serialized, arguments: fixtures) func testAsyncBytesBulkRead(fixture: Fixture) async throws {
    func unwrap<T: FileReference>(_ fileRef: T) async throws {
        // read entire file
        try await withBytes(fileRef, range: 0..<fileRef.size) { bytes in
            let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 10240, alignment: 1)
            defer { buffer.deallocate() }

            var iterator = bytes.makeAsyncIterator()

            var length = try await iterator.getBytes(buffer)
            #expect(Data(buffer.prefix(length)) == fixtureData.prefix(length))

            length = try await iterator.getBytes(buffer)
            #expect(Data(buffer.prefix(length)) == fixtureData[(fixtureData.startIndex + 10240)...].prefix(10240))
        }

        // read arbitrary ranges
        try await withBytes(fileRef, range: 0x1000..<0x2500) { bytes in
            let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 0x1000, alignment: 1)
            defer { buffer.deallocate() }

            var iterator = bytes.makeAsyncIterator()

            var length = try await iterator.getBytes(buffer)
            #expect(Data(buffer.prefix(length)) == fixtureData[(fixtureData.startIndex + 0x1000)...].prefix(0x1000))

            length = try await iterator.getBytes(buffer)
            #expect(Data(buffer.prefix(length)) == fixtureData[(fixtureData.startIndex + 0x2000)...].prefix(0x500))
        }
    }

    try await unwrap(try await fixture.constructor())
}

@Test(.serialized, arguments: fixtures) func testSlice(fixture: Fixture) async throws {
    func unwrap<T: FileReference>(_ ref: T) async throws {
        var para = ref.getSlice(in: 1156..<1550)

        // read entire slice sync
        #expect(try await readBytes(para, 0..<para.size) == fixtureData[1156..<1550])

        // read entire slice async
        try await withBytes(para, range: 0..<para.size) { bytes in
            var index = 1156
            for try await byte in bytes {
                #expect(byte == fixtureData[index])
                index += 1
            }
        }

        // read portion sync
        #expect(try await readBytes(para, 194..<230) == fixtureData[1350..<1386])

        // read portion async
        try await withBytes(para, range: 194..<230) { bytes in
            var index = 1350
            for try await byte in bytes {
                #expect(byte == fixtureData[index])
                index += 1
            }
        }

        // should throw errors if used after closing
        try para.close()
        await #expect(throws: FileReferenceError.closed) { try await readBytes(para, 0..<para.size) }
        await #expect(throws: FileReferenceError.closed) {
            try await withBytes(para, range: 0..<para.size) {
                _ = try await $0.first(where: { _ in true })
            }
        }
        await #expect(throws: FileReferenceError.closed) { try await readBytes(para, 194..<230) }
        await #expect(throws: FileReferenceError.closed) {
            try await withBytes(para, range: 194..<230) { _ = try await $0.first(where: { _ in true }) }
        }
    }

    try await unwrap(fixture.constructor())
}

@Test(.serialized, arguments: fixtures) func readAfterClose(fixture: Fixture) async throws {
    func unwrap<T: FileReference>(_ ref: T) async throws {
        var fileRef = ref
        try fileRef.close()

        await #expect(throws: FileReferenceError.closed) { try await fileRef.getData(in: 0..<fileRef.size) }
        await #expect(throws: FileReferenceError.closed) { try await fileRef.getData(in: 0x18..<0x28) }

        let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: Int(fileRef.size), alignment: 1)
        defer { buf.deallocate() }
        await #expect(throws: FileReferenceError.closed) { try await fileRef.getBytes(buf, in: 0..<fileRef.size) }
        await #expect(throws: FileReferenceError.closed) { try await fileRef.getBytes(buf, in: 0x18..<0x28) }

        await #expect(throws: FileReferenceError.closed) {
            _ = try await fileRef.getAsyncBytes(in: 0..<fileRef.size).first { _ in true }
        }
        await #expect(throws: FileReferenceError.closed) {
            try await fileRef.getAsyncBytes(in: 0x18..<0x28).first { _ in true }
        }
    }

    try await unwrap(fixture.constructor())
}

@Test func directFileDescriptorAccess() async throws {
    let file = try FileDescriptor.open(fixtureURL.path, .readOnly)
    defer { try? file.close() }

    try SystemFileReference(fileDescriptor: file, closeWhenDone: false).withRawDescriptorAccess { fd in
        #expect(fd == file)
    }

    try RawPOSIXFileReference(fileDescriptor: file.rawValue, closeWhenDone: false).withRawDescriptorAccess { fd in
        #expect(fd == file.rawValue)
    }
}

private func readBytes<F: FileReference>(_ ref: F, _ range: Range<UInt64>) async throws -> Data {
    let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: range.count, alignment: 1)
    defer { buf.deallocate() }

    let bytesRead = try await ref.getBytes(buf, in: range)

    return Data(buf.prefix(bytesRead))
}

private func withBytes<R, F: FileReference>(
    _ ref: F,
    range: Range<UInt64>,
    _ closure: (AsyncBytes<F>) async throws -> R
) async throws -> R {
    let bytes = try ref.getAsyncBytes(in: range)
    return try await closure(bytes)
}

private func withBytes<R, F: FileReference>(
    _ ref: F,
    offset: some BinaryInteger,
    length: some BinaryInteger,
    _ closure: (AsyncBytes<F>) async throws -> R
) async throws -> R{
    let bytes = try ref.getAsyncBytes(at: offset, length: length)
    return try await closure(bytes)
}
