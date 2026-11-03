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
import SystemFileReference
import Testing

@SystemFileReference
func syncStandaloneFunction<F: FileReference>(file: F, closure: (F) throws -> Void) throws {
    try closure(file)
}

@SystemFileReference
func asyncStandaloneFunction<F: FileReference>(file: F, closure: (F) throws -> Void) async throws {
    try closure(file)
}

class SyncFileHolder<F: FileReference> {
    let file: F

    @SystemFileReference
    init(file: F) throws { self.file = file }
}

struct AsyncFileHolder<F: FileReference> {
    let file: F

    @SystemFileReference
    init(file: F) async throws { self.file = file }
}

struct MacroTestFixture: CustomTestStringConvertible, Identifiable, Sendable {
    let name: String
    let withFileReference: @Sendable ((SystemFileReference) throws -> Void) async throws -> Void

    var testDescription: String { self.name }
    var id: String { self.name }
}

let fixturePath = FilePath(fixtureURL.path(percentEncoded: false))

#if Foundation
private let foundationFixtures = [
    MacroTestFixture(name: "sync function by url") { try syncStandaloneFunction(url: fixtureURL, closure: $0) },
    MacroTestFixture(name: "async function by url") { try await asyncStandaloneFunction(url: fixtureURL, closure: $0) },
    MacroTestFixture(name: "sync init by url") { try $0(SyncFileHolder(url: fixtureURL).file) },
    MacroTestFixture(name: "async init by url") { try await $0(AsyncFileHolder(url: fixtureURL).file) }
]
#else
private let foundationFixtures: [MacroTestFixture] = []
#endif

let macroTestFixtures = [
    MacroTestFixture(name: "sync function by path") { try syncStandaloneFunction(path: fixturePath, closure: $0) },
    MacroTestFixture(name: "sync function by descriptor") {
        let descriptor = try FileDescriptor.open(fixturePath, .readOnly)
        try syncStandaloneFunction(fileDescriptor: descriptor, closeWhenDone: true, closure: $0)
    },
    MacroTestFixture(name: "async function by path") { try await asyncStandaloneFunction(path: fixturePath, closure: $0) },
    MacroTestFixture(name: "async function by descriptor") {
        let descriptor = try FileDescriptor.open(fixturePath, .readOnly)
        try await asyncStandaloneFunction(fileDescriptor: descriptor, closeWhenDone: true, closure: $0)
    },
    MacroTestFixture(name: "sync init by path") { try $0(SyncFileHolder(path: fixturePath).file) },
    MacroTestFixture(name: "sync init by descriptor") {
        let descriptor = try FileDescriptor.open(fixturePath, .readOnly)
        try $0(SyncFileHolder(fileDescriptor: descriptor, closeWhenDone: true).file)
    },
    MacroTestFixture(name: "async init by path") { try await $0(AsyncFileHolder(path: fixturePath).file) },
    MacroTestFixture(name: "async init by descriptor") {
        let descriptor = try FileDescriptor.open(fixturePath, .readOnly)
        try await $0(AsyncFileHolder(fileDescriptor: descriptor, closeWhenDone: true).file)
    }
] + foundationFixtures

@Test(arguments: macroTestFixtures)
func testMacro(fixture: MacroTestFixture) async throws {
    try await fixture.withFileReference { ref in
        defer { try? ref.close() }

        #expect(ref.size == 12475)
        try #expect(String(bytes: ref.syncGetData(in: 0..<20), encoding: .utf8) == "CHAPTER 1. Loomings.")
        try #expect(String(bytes: ref.syncGetData(in: 0xd9d..<0xdb3), encoding: .utf8) == "But here is an artist.")
    }
}

#endif
