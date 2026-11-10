//
//  MacroTests.swift
//  CSFileReference
//
//  Created by Charles Srstka on 10/31/26.
//

#if Macros

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

import FileReference
import Foundation
import Testing

@FileReference(.filePath("at"), .fileDescriptor("file"), .rawData("data"), .url("at"))
private func syncStandaloneFunction<F: SyncFileReference>(file: F, closure: (F) throws -> Void) throws {
    try closure(file)
}

@FileReference(.filePath("at"), .fileDescriptor("file"), .rawData("data"), .url("at"))
private func asyncStandaloneFunction<F: FileReference>(file: F, closure: (F) throws -> Void) async throws {
    try closure(file)
}

@FileReference(.filePath("at"), .fileDescriptor("file"), .rawData("data"), .url("at"), defaultReturn: 0)
private func syncNonThrowingFunction(file: some SyncFileReference) -> UInt64 { file.size }

@FileReference(.filePath("at"), .fileDescriptor("file"), .rawData("data"), .url("at"), defaultReturn: 0)
private func asyncNonThrowingFunction(file: some FileReference) async -> UInt64 {
    try? await Task.sleep(nanoseconds: 1)
    return file.size
}

@FileReference(.filePath("at"))
private func convertibleAsyncFunction(file: some FileReference) async throws -> String {
    let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: 1000, alignment: 1)
    defer { buf.deallocate() }

    let count = try await file.getBytes(buf, in: 0..<20)

    return buf.prefix(count).withMemoryRebound(to: UInt8.self) { String(decoding: $0, as: UTF8.self) }
}

@FileReference(.filePath("at"))
private func nonConvertibleAsyncFunction(file: some FileReference) async throws -> String {
    try await Task.sleep(nanoseconds: 1_000_000)
    return try await String(decoding: file.getData(in: 0..<20), as: UTF8.self)
}

private class SyncFileHolder<F: FileReference> {
    let file: F

    @FileReference(.filePath("at"), .fileDescriptor("file"), .rawData("data"), .url("at"))
    init(file: F) throws { self.file = file }
}

private struct AsyncFileHolder<F: FileReference> {
    let file: F

    @FileReference(.filePath("at"), .fileDescriptor("file"), .rawData("data"), .url("at"))
    init(file: F) async throws { self.file = file }
}

struct MacroTestFixture: CustomTestStringConvertible, Identifiable, Sendable {
    let name: String
    let withFileReference: @Sendable ((any SyncFileReference) throws -> Void) async throws -> Void

    var testDescription: String { self.name }
    var id: String { self.name }
}

let fixturePath = FilePath(fixtureURL.path(percentEncoded: false))

#if Foundation
private let foundationFixtures = [
    MacroTestFixture(name: "sync function by url") { try syncStandaloneFunction(at: fixtureURL, closure: $0) },
    MacroTestFixture(name: "async function by url") { try asyncStandaloneFunction(at: fixtureURL, closure: $0) },
    MacroTestFixture(name: "sync init by url") { try $0(SyncFileHolder(at: fixtureURL).file) },
    MacroTestFixture(name: "async init by url") { try $0(AsyncFileHolder(at: fixtureURL).file) }
]
#else
private let foundationFixtures: [MacroTestFixture] = []
#endif

let macroTestFixtures = [
    MacroTestFixture(name: "sync function by path") { try syncStandaloneFunction(at: fixturePath, closure: $0) },
    MacroTestFixture(name: "sync function by descriptor") {
        let descriptor = try FileDescriptor.open(fixturePath, .readOnly)
        try syncStandaloneFunction(file: descriptor, closeWhenDone: true, closure: $0)
    },
    MacroTestFixture(name: "sync function by data") { try syncStandaloneFunction(data: fixtureData, closure: $0) },
    MacroTestFixture(name: "async function by path") { try asyncStandaloneFunction(at: fixturePath, closure: $0) },
    MacroTestFixture(name: "async function by descriptor") {
        let descriptor = try FileDescriptor.open(fixturePath, .readOnly)
        try asyncStandaloneFunction(file: descriptor, closeWhenDone: true, closure: $0)
    },
    MacroTestFixture(name: "async function by data") { try asyncStandaloneFunction(data: fixtureData, closure: $0) },
    MacroTestFixture(name: "sync init by path") { try $0(SyncFileHolder(at: fixturePath).file) },
    MacroTestFixture(name: "sync init by descriptor") {
        let descriptor = try FileDescriptor.open(fixturePath, .readOnly)
        try $0(SyncFileHolder(file: descriptor, closeWhenDone: true).file)
    },
    MacroTestFixture(name: "sync init by data") { try $0(SyncFileHolder(data: fixtureData).file) },
    MacroTestFixture(name: "async init by path") { try $0(AsyncFileHolder(at: fixturePath).file) },
    MacroTestFixture(name: "async init by descriptor") {
        let descriptor = try FileDescriptor.open(fixturePath, .readOnly)
        try $0(AsyncFileHolder(file: descriptor, closeWhenDone: true).file)
    },
    MacroTestFixture(name: "async init by data") { try $0(AsyncFileHolder(data: fixtureData).file) },
] + foundationFixtures

@Test(arguments: macroTestFixtures)
func testMacro(fixture: MacroTestFixture) async throws {
    try await fixture.withFileReference {
        var ref = $0
        defer { try? ref.close() }

        #expect(ref.size == 12475)
        try #expect(String(bytes: ref.syncGetData(in: 0..<20), encoding: .utf8) == "CHAPTER 1. Loomings.")
        try #expect(String(bytes: ref.syncGetData(in: 0xd9d..<0xdb3), encoding: .utf8) == "But here is an artist.")
    }
}

@Test
func testNonThrowingFunctions() async throws {
    let file = try FileDescriptor.open(fixturePath, .readOnly)
    defer { try? file.close() }

    #expect(await asyncNonThrowingFunction(at: fixturePath) == 12475)
    #expect(await asyncNonThrowingFunction(file: file, closeWhenDone: false) == 12475)
    #expect(await asyncNonThrowingFunction(data: [0x00, 0x01, 0x02]) == 3)

    #expect(syncNonThrowingFunction(at: fixturePath) == 12475)
    #expect(syncNonThrowingFunction(file: file, closeWhenDone: false) == 12475)
    #expect(syncNonThrowingFunction(data: [0x00, 0x01, 0x02]) == 3)

#if Foundation
    #expect(await asyncNonThrowingFunction(at: fixtureURL) == 12475)
    #expect(syncNonThrowingFunction(at: fixtureURL) == 12475)
#endif
}

@Test
func testAsyncToSyncConversion() async throws {
    try #expect(convertibleAsyncFunction(at: fixturePath) == "CHAPTER 1. Loomings.")
    try await #expect(nonConvertibleAsyncFunction(at: fixturePath) == "CHAPTER 1. Loomings.")
}

#endif
