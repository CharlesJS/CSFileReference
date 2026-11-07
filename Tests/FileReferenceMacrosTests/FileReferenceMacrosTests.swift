//
//  FileReferenceMacrosTests.swift
//  CSFileReference
//
//  Created by Charles Srstka on 10/28/26.
//

#if Macros

import FileReferenceMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite("@FileReference macro")
struct MacroTests {
    private static let macros = ["FileReference": FileReferenceMacro.self]

    @Suite("Async function")
    struct AsyncFunction {
        @Test("some")
        func expandsAsyncFunctionWithSome() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo(ref: some FileReference) async throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo(ref: some FileReference) async throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath) async throws -> String {
                    try await foo(ref: SystemFileReference(path: path))
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws -> String {
                    try await foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                }
                
                func foo(data: some Collection<UInt8>) async throws -> String {
                    try await foo(ref: RawDataFileReference(data: data))
                }
                """,
                foundationSource: """
                func foo(url: URL) async throws -> String {
                    try await foo(ref: SystemFileReference(url: url))
                }
                """
            )
        }

        @Test("any")
        func expandsAsyncFunctionWithAny() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo(ref: any FileReference) async throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo(ref: any FileReference) async throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath) async throws -> String {
                    try await foo(ref: SystemFileReference(path: path))
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws -> String {
                    try await foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                }

                func foo(data: some Collection<UInt8>) async throws -> String {
                    try await foo(ref: RawDataFileReference(data: data))
                }
                """,
                foundationSource: """
                func foo(url: URL) async throws -> String {
                    try await foo(ref: SystemFileReference(url: url))
                }
                """
            )
        }

        @Test("generic parameter")
        func expandsAsyncFunctionWithGenericParameter() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: FileReference>(ref: R) async throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<R: FileReference>(ref: R) async throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath) async throws -> String {
                    try await foo(ref: SystemFileReference(path: path))
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws -> String {
                    try await foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                }

                func foo(data: some Collection<UInt8>) async throws -> String {
                    try await foo(ref: RawDataFileReference(data: data))
                }
                """,
                foundationSource: """
                func foo(url: URL) async throws -> String {
                    try await foo(ref: SystemFileReference(url: url))
                }
                """
            )
        }

        @Test("generic parameter referenced in other generic parameter")
        func expandsAsyncFunctionWithGenericParameterReferencedInOtherGenericParameter() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: FileReference>(ref: R, array: Array<R>) async throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<R: FileReference>(ref: R, array: Array<R>) async throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath, array: Array<SystemFileReference>) async throws -> String {
                    try await foo(ref: SystemFileReference(path: path), array: array)
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: Array<SystemFileReference>) async throws -> String {
                    try await foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                }

                func foo(data: some Collection<UInt8>, array: Array<RawDataFileReference>) async throws -> String {
                    try await foo(ref: RawDataFileReference(data: data), array: array)
                }
                """,
                foundationSource: """
                func foo(url: URL, array: Array<SystemFileReference>) async throws -> String {
                    try await foo(ref: SystemFileReference(url: url), array: array)
                }
                """
            )
        }

        @Test("generic parameter referenced in array parameter")
        func expandsAsyncFunctionWithGenericParameterReferencedInArrayParameter() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: FileReference>(ref: R, array: [R]) async throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<R: FileReference>(ref: R, array: [R]) async throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath, array: [SystemFileReference]) async throws -> String {
                    try await foo(ref: SystemFileReference(path: path), array: array)
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: [SystemFileReference]) async throws -> String {
                    try await foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                }

                func foo(data: some Collection<UInt8>, array: [RawDataFileReference]) async throws -> String {
                    try await foo(ref: RawDataFileReference(data: data), array: array)
                }
                """,
                foundationSource: """
                func foo(url: URL, array: [SystemFileReference]) async throws -> String {
                    try await foo(ref: SystemFileReference(url: url), array: array)
                }
                """
            )
        }

        @Test("generic parameter referenced in dictionary parameter")
        func expandsAsyncFunctionWithGenericParameterReferencedInDictionary() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: FileReference>(ref: R, dict: [String : R]) async throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<R: FileReference>(ref: R, dict: [String : R]) async throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath, dict: [String : SystemFileReference]) async throws -> String {
                    try await foo(ref: SystemFileReference(path: path), dict: dict)
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool, dict: [String : SystemFileReference]) async throws -> String {
                    try await foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), dict: dict)
                }

                func foo(data: some Collection<UInt8>, dict: [String : RawDataFileReference]) async throws -> String {
                    try await foo(ref: RawDataFileReference(data: data), dict: dict)
                }
                """,
                foundationSource: """
                func foo(url: URL, dict: [String : SystemFileReference]) async throws -> String {
                    try await foo(ref: SystemFileReference(url: url), dict: dict)
                }
                """
            )
        }

        @Test("generic parameter referenced in closure")
        func expandsAsyncFunctionWithGenericParameterReferencedInClosure() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: FileReference>(ref: R, closure: (R) -> Void) async throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<R: FileReference>(ref: R, closure: (R) -> Void) async throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath, closure: (SystemFileReference) -> Void) async throws -> String {
                    try await foo(ref: SystemFileReference(path: path), closure: closure)
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool, closure: (SystemFileReference) -> Void) async throws -> String {
                    try await foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), closure: closure)
                }

                func foo(data: some Collection<UInt8>, closure: (RawDataFileReference) -> Void) async throws -> String {
                    try await foo(ref: RawDataFileReference(data: data), closure: closure)
                }
                """,
                foundationSource: """
                func foo(url: URL, closure: (SystemFileReference) -> Void) async throws -> String {
                    try await foo(ref: SystemFileReference(url: url), closure: closure)
                }
                """
            )
        }

        @Test("multiple generic parameters")
        func expandsAsyncFunctionWithMultipleGenericParameters() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) async throws -> S {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) async throws -> S {
                    return "Foo"
                }

                func foo<S: StringProtocol>(type: S.Type, path: FilePath) async throws -> S {
                    try await foo(type: type, ref: SystemFileReference(path: path))
                }

                func foo<S: StringProtocol>(type: S.Type, fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws -> S {
                    try await foo(type: type, ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                }

                func foo<S: StringProtocol>(type: S.Type, data: some Collection<UInt8>) async throws -> S {
                    try await foo(type: type, ref: RawDataFileReference(data: data))
                }
                """,
                foundationSource: """
                func foo<S: StringProtocol>(type: S.Type, url: URL) async throws -> S {
                    try await foo(type: type, ref: SystemFileReference(url: url))
                }
                """
            )

            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) async throws -> S {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) async throws -> S {
                    return "Foo"
                }

                func foo<S: StringProtocol>(path: FilePath, type: S.Type) async throws -> S {
                    try await foo(ref: SystemFileReference(path: path), type: type)
                }

                func foo<S: StringProtocol>(fileDescriptor: FileDescriptor, closeWhenDone: Bool, type: S.Type) async throws -> S {
                    try await foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), type: type)
                }

                func foo<S: StringProtocol>(data: some Collection<UInt8>, type: S.Type) async throws -> S {
                    try await foo(ref: RawDataFileReference(data: data), type: type)
                }
                """,
                foundationSource: """
                func foo<S: StringProtocol>(url: URL, type: S.Type) async throws -> S {
                    try await foo(ref: SystemFileReference(url: url), type: type)
                }
                """
            )
        }

        @Test("returning generic parameter")
        func expandsAsyncFunctionReturningGenericParameter() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: FileReference>(ref: R) async throws -> R {
                    return ref
                }
                """,
                expandedSource: """
                func foo<R: FileReference>(ref: R) async throws -> R {
                    return ref
                }

                func foo(path: FilePath) async throws -> SystemFileReference {
                    try await foo(ref: SystemFileReference(path: path))
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws -> SystemFileReference {
                    try await foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                }

                func foo(data: some Collection<UInt8>) async throws -> RawDataFileReference {
                    try await foo(ref: RawDataFileReference(data: data))
                }
                """,
                foundationSource: """
                func foo(url: URL) async throws -> SystemFileReference {
                    try await foo(ref: SystemFileReference(url: url))
                }
                """
            )
        }
    }

    @Suite("Sync function")
    struct SyncFunction {
        @Test("some")
        func expandsSyncFunctionWithSome() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo(reference: some SyncFileReference) throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo(reference: some SyncFileReference) throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath) throws -> String {
                    try foo(reference: SystemFileReference(path: path))
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws -> String {
                    try foo(reference: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                }

                func foo(data: some Collection<UInt8>) throws -> String {
                    try foo(reference: RawDataFileReference(data: data))
                }
                """,
                foundationSource: """
                func foo(url: URL) throws -> String {
                    try foo(reference: SystemFileReference(url: url))
                }
                """
            )
        }

        @Test("any")
        func expandsSyncFunctionWithAny() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo(reference: any SyncFileReference) throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo(reference: any SyncFileReference) throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath) throws -> String {
                    try foo(reference: SystemFileReference(path: path))
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws -> String {
                    try foo(reference: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                }

                func foo(data: some Collection<UInt8>) throws -> String {
                    try foo(reference: RawDataFileReference(data: data))
                }
                """,
                foundationSource: """
                func foo(url: URL) throws -> String {
                    try foo(reference: SystemFileReference(url: url))
                }
                """
            )
        }

        @Test("generic parameter")
        func expandsSyncFunctionWithGenericParameter() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: SyncFileReference>(ref: R) throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<R: SyncFileReference>(ref: R) throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath) throws -> String {
                    try foo(ref: SystemFileReference(path: path))
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws -> String {
                    try foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                }

                func foo(data: some Collection<UInt8>) throws -> String {
                    try foo(ref: RawDataFileReference(data: data))
                }
                """,
                foundationSource: """
                func foo(url: URL) throws -> String {
                    try foo(ref: SystemFileReference(url: url))
                }
                """
            )
        }

        @Test("generic parameter referenced in other generic parameter")
        func expandsSyncFunctionWithGenericParameterReferencedInOtherGenericParameter() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: SyncFileReference>(ref: R, array: Array<R>) throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<R: SyncFileReference>(ref: R, array: Array<R>) throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath, array: Array<SystemFileReference>) throws -> String {
                    try foo(ref: SystemFileReference(path: path), array: array)
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: Array<SystemFileReference>) throws -> String {
                    try foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                }

                func foo(data: some Collection<UInt8>, array: Array<RawDataFileReference>) throws -> String {
                    try foo(ref: RawDataFileReference(data: data), array: array)
                }
                """,
                foundationSource: """
                func foo(url: URL, array: Array<SystemFileReference>) throws -> String {
                    try foo(ref: SystemFileReference(url: url), array: array)
                }
                """
            )
        }

        @Test("generic parameter referenced in array parameter")
        func expandsSyncFunctionWithGenericParameterReferencedInArrayParameter() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: SyncFileReference>(ref: R, array: [R]) throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<R: SyncFileReference>(ref: R, array: [R]) throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath, array: [SystemFileReference]) throws -> String {
                    try foo(ref: SystemFileReference(path: path), array: array)
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: [SystemFileReference]) throws -> String {
                    try foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                }

                func foo(data: some Collection<UInt8>, array: [RawDataFileReference]) throws -> String {
                    try foo(ref: RawDataFileReference(data: data), array: array)
                }
                """,
                foundationSource: """
                func foo(url: URL, array: [SystemFileReference]) throws -> String {
                    try foo(ref: SystemFileReference(url: url), array: array)
                }
                """
            )
        }

        @Test("generic parameter referenced in dictionary parameter")
        func expandsSyncFunctionWithGenericParameterReferencedInDictionary() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: SyncFileReference>(ref: R, dict: [String : R]) throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<R: SyncFileReference>(ref: R, dict: [String : R]) throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath, dict: [String : SystemFileReference]) throws -> String {
                    try foo(ref: SystemFileReference(path: path), dict: dict)
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool, dict: [String : SystemFileReference]) throws -> String {
                    try foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), dict: dict)
                }

                func foo(data: some Collection<UInt8>, dict: [String : RawDataFileReference]) throws -> String {
                    try foo(ref: RawDataFileReference(data: data), dict: dict)
                }
                """,
                foundationSource: """
                func foo(url: URL, dict: [String : SystemFileReference]) throws -> String {
                    try foo(ref: SystemFileReference(url: url), dict: dict)
                }
                """
            )
        }

        @Test("generic parameter referenced in closure")
        func expandsSyncFunctionWithGenericParameterReferencedInClosure() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: SyncFileReference>(ref: R, closure: (R) -> Void) throws -> String {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<R: SyncFileReference>(ref: R, closure: (R) -> Void) throws -> String {
                    return "Foo"
                }

                func foo(path: FilePath, closure: (SystemFileReference) -> Void) throws -> String {
                    try foo(ref: SystemFileReference(path: path), closure: closure)
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool, closure: (SystemFileReference) -> Void) throws -> String {
                    try foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), closure: closure)
                }

                func foo(data: some Collection<UInt8>, closure: (RawDataFileReference) -> Void) throws -> String {
                    try foo(ref: RawDataFileReference(data: data), closure: closure)
                }
                """,
                foundationSource: """
                func foo(url: URL, closure: (SystemFileReference) -> Void) throws -> String {
                    try foo(ref: SystemFileReference(url: url), closure: closure)
                }
                """
            )
        }

        @Test("multiple generic parameters")
        func expandsSyncFunctionWithMultipleGenericParameters() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<S: StringProtocol, R: SyncFileReference>(type: S.Type, ref: R) throws -> S {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<S: StringProtocol, R: SyncFileReference>(type: S.Type, ref: R) throws -> S {
                    return "Foo"
                }

                func foo<S: StringProtocol>(type: S.Type, path: FilePath) throws -> S {
                    try foo(type: type, ref: SystemFileReference(path: path))
                }

                func foo<S: StringProtocol>(type: S.Type, fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws -> S {
                    try foo(type: type, ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                }

                func foo<S: StringProtocol>(type: S.Type, data: some Collection<UInt8>) throws -> S {
                    try foo(type: type, ref: RawDataFileReference(data: data))
                }
                """,
                foundationSource: """
                func foo<S: StringProtocol>(type: S.Type, url: URL) throws -> S {
                    try foo(type: type, ref: SystemFileReference(url: url))
                }
                """
                )

                MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: SyncFileReference, S: StringProtocol>(ref: R, type: S.Type) throws -> S {
                    return "Foo"
                }
                """,
                expandedSource: """
                func foo<R: SyncFileReference, S: StringProtocol>(ref: R, type: S.Type) throws -> S {
                    return "Foo"
                }

                func foo<S: StringProtocol>(path: FilePath, type: S.Type) throws -> S {
                    try foo(ref: SystemFileReference(path: path), type: type)
                }

                func foo<S: StringProtocol>(fileDescriptor: FileDescriptor, closeWhenDone: Bool, type: S.Type) throws -> S {
                    try foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), type: type)
                }

                func foo<S: StringProtocol>(data: some Collection<UInt8>, type: S.Type) throws -> S {
                    try foo(ref: RawDataFileReference(data: data), type: type)
                }
                """,
                foundationSource: """
                func foo<S: StringProtocol>(url: URL, type: S.Type) throws -> S {
                    try foo(ref: SystemFileReference(url: url), type: type)
                }
                """
            )
        }

        @Test("returning generic parameter")
        func expandsSyncFunctionReturningGenericParameter() {
            MacroTests.expectExpansion(
                """
                @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                func foo<R: SyncFileReference>(ref: R) throws -> R {
                    return ref
                }
                """,
                expandedSource: """
                func foo<R: SyncFileReference>(ref: R) throws -> R {
                    return ref
                }

                func foo(path: FilePath) throws -> SystemFileReference {
                    try foo(ref: SystemFileReference(path: path))
                }

                func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws -> SystemFileReference {
                    try foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                }

                func foo(data: some Collection<UInt8>) throws -> RawDataFileReference {
                    try foo(ref: RawDataFileReference(data: data))
                }
                """,
                foundationSource: """
                func foo(url: URL) throws -> SystemFileReference {
                    try foo(ref: SystemFileReference(url: url))
                }
                """
            )
        }
    }

    @Suite("Struct initializer")
    struct StructInitializer {
        @Suite("async")
        struct Async {
            @Test("some")
            func expandsAsyncInitializerWithSome() {
                MacroTests.expectExpansion(
                    """
                    struct ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(ref: some FileReference) async throws {
                            print("initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    struct ParentType {
                        init(ref: some FileReference) async throws {
                            print("initialize something")
                        }

                        init(path: FilePath) async throws {
                            try await self.init(ref: SystemFileReference(path: path))
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        init(data: some Collection<UInt8>) async throws {
                            try await self.init(ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL) async throws {
                            try await self.init(ref: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("any")
            func expandsAsyncInitializerWithAny() {
                MacroTests.expectExpansion(
                    """
                    struct ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(ref: any FileReference) async throws {
                            print("initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    struct ParentType {
                        init(ref: any FileReference) async throws {
                            print("initialize something")
                        }

                        init(path: FilePath) async throws {
                            try await self.init(ref: SystemFileReference(path: path))
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        init(data: some Collection<UInt8>) async throws {
                            try await self.init(ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL) async throws {
                            try await self.init(ref: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("generic parameter")
            func expandsAsyncInitializerWithGenericParameter() {
                MacroTests.expectExpansion(
                    """
                    struct ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    struct ParentType {
                        init<R: FileReference>(ref: R) async throws {
                            print("Initialize something")
                        }

                        init(path: FilePath) async throws {
                            try await self.init(ref: SystemFileReference(path: path))
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        init(data: some Collection<UInt8>) async throws {
                            try await self.init(ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL) async throws {
                            try await self.init(ref: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("generic parameter on parent type")
            func expandsAsyncInitializerWithGenericParameterOnType() {
                MacroTests.expectExpansion(
                    """
                    struct ParentType<F: FileReference> {
                        let file: F

                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(file: F) async throws {
                            self.file = file
                        }
                    }
                    """,
                    expandedSource: """
                    struct ParentType<F: FileReference> {
                        let file: F
                        init(file: F) async throws {
                            self.file = file
                        }

                        init(path: FilePath) async throws where F == SystemFileReference {
                            try await self.init(file: SystemFileReference(path: path))
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws where F == SystemFileReference {
                            try await self.init(file: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        init(data: some Collection<UInt8>) async throws where F == RawDataFileReference {
                            try await self.init(file: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL) async throws where F == SystemFileReference {
                            try await self.init(file: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("generic parameter referenced in other generic parameter")
            func expandsAsyncInitializerWithGenericParameterReferencedInOtherGenericParameter() {
                MacroTests.expectExpansion(
                    """
                    struct ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R, array: Array<R>) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    struct ParentType {
                        init<R: FileReference>(ref: R, array: Array<R>) async throws {
                            print("Initialize something")
                        }

                        init(path: FilePath, array: Array<SystemFileReference>) async throws {
                            try await self.init(ref: SystemFileReference(path: path), array: array)
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: Array<SystemFileReference>) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                        }
                    
                        init(data: some Collection<UInt8>, array: Array<RawDataFileReference>) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), array: array)
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL, array: Array<SystemFileReference>) async throws {
                            try await self.init(ref: SystemFileReference(url: url), array: array)
                        }
                    """
                )
            }

            @Test("generic parameter referenced in array parameter")
            func expandsAsyncInitializerWithGenericParameterReferencedInArrayParameter() {
                MacroTests.expectExpansion(
                    """
                    struct ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R, array: [R]) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    struct ParentType {
                        init<R: FileReference>(ref: R, array: [R]) async throws {
                            print("Initialize something")
                        }

                        init(path: FilePath, array: [SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(path: path), array: array)
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: [SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                        }

                        init(data: some Collection<UInt8>, array: [RawDataFileReference]) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), array: array)
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL, array: [SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(url: url), array: array)
                        }
                    """
                )
            }

            @Test("generic parameter referenced in dictionary parameter")
            func expandsAsyncInitializerWithGenericParameterReferencedInDictionary() {
                MacroTests.expectExpansion(
                    """
                    struct ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R, dict: [String : R]) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    struct ParentType {
                        init<R: FileReference>(ref: R, dict: [String : R]) async throws {
                            print("Initialize something")
                        }

                        init(path: FilePath, dict: [String : SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(path: path), dict: dict)
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, dict: [String : SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), dict: dict)
                        }

                        init(data: some Collection<UInt8>, dict: [String : RawDataFileReference]) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), dict: dict)
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL, dict: [String : SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(url: url), dict: dict)
                        }
                    """
                )
            }

            @Test("generic parameter referenced in closure")
            func expandsAsyncInitializerWithGenericParameterReferencedInClosure() {
                MacroTests.expectExpansion(
                    """
                    struct ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R, closure: (R) -> Void) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    struct ParentType {
                        init<R: FileReference>(ref: R, closure: (R) -> Void) async throws {
                            print("Initialize something")
                        }

                        init(path: FilePath, closure: (SystemFileReference) -> Void) async throws {
                            try await self.init(ref: SystemFileReference(path: path), closure: closure)
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, closure: (SystemFileReference) -> Void) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), closure: closure)
                        }

                        init(data: some Collection<UInt8>, closure: (RawDataFileReference) -> Void) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), closure: closure)
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL, closure: (SystemFileReference) -> Void) async throws {
                            try await self.init(ref: SystemFileReference(url: url), closure: closure)
                        }
                    """
                )
            }

            @Test("multiple generic parameters")
            func expandsAsyncInitializerWithMultipleGenericParameters() {
                MacroTests.expectExpansion(
                    """
                    struct ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    struct ParentType {
                        init<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) async throws {
                            print("Initialize something")
                        }

                        init<S: StringProtocol>(type: S.Type, path: FilePath) async throws {
                            try await self.init(type: type, ref: SystemFileReference(path: path))
                        }

                        init<S: StringProtocol>(type: S.Type, fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws {
                            try await self.init(type: type, ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        init<S: StringProtocol>(type: S.Type, data: some Collection<UInt8>) async throws {
                            try await self.init(type: type, ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init<S: StringProtocol>(type: S.Type, url: URL) async throws {
                            try await self.init(type: type, ref: SystemFileReference(url: url))
                        }
                    """
                )

                MacroTests.expectExpansion(
                    """
                    struct ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    struct ParentType {
                        init<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) async throws {
                            print("Initialize something")
                        }

                        init<S: StringProtocol>(path: FilePath, type: S.Type) async throws {
                            try await self.init(ref: SystemFileReference(path: path), type: type)
                        }

                        init<S: StringProtocol>(fileDescriptor: FileDescriptor, closeWhenDone: Bool, type: S.Type) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), type: type)
                        }

                        init<S: StringProtocol>(data: some Collection<UInt8>, type: S.Type) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), type: type)
                        }
                    }
                    """,
                    foundationSource: """
                        init<S: StringProtocol>(url: URL, type: S.Type) async throws {
                            try await self.init(ref: SystemFileReference(url: url), type: type)
                        }
                    """
                )
            }
        }

        @Suite("sync")
        struct Sync {
            @Test("some")
            func expandsSyncInitializerWithSome() {
                MacroTests.expectExpansion(
                    """
                    struct ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(ref: some SyncFileReference) throws {
                            print("initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    struct ParentType {
                        init(ref: some SyncFileReference) throws {
                            print("initialize something")
                        }

                        init(path: FilePath) throws {
                            try self.init(ref: SystemFileReference(path: path))
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
                            try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        init(data: some Collection<UInt8>) throws {
                            try self.init(ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL) throws {
                            try self.init(ref: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("any")
            func expandsSyncInitializerWithAny() {
                MacroTests.expectExpansion(
                """
                struct ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init(ref: any SyncFileReference) throws {
                        print("initialize something")
                    }
                }
                """,
                expandedSource: """
                struct ParentType {
                    init(ref: any SyncFileReference) throws {
                        print("initialize something")
                    }

                    init(path: FilePath) throws {
                        try self.init(ref: SystemFileReference(path: path))
                    }

                    init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                    }

                    init(data: some Collection<UInt8>) throws {
                        try self.init(ref: RawDataFileReference(data: data))
                    }
                }
                """,
                foundationSource: """
                    init(url: URL) throws {
                        try self.init(ref: SystemFileReference(url: url))
                    }
                """
                )
            }

            @Test("generic parameter")
            func expandsSyncInitializerWithGenericParameter() {
                MacroTests.expectExpansion(
                """
                struct ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                struct ParentType {
                    init<R: FileReference>(ref: R) throws {
                        print("Initialize something")
                    }

                    init(path: FilePath) throws {
                        try self.init(ref: SystemFileReference(path: path))
                    }

                    init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                    }

                    init(data: some Collection<UInt8>) throws {
                        try self.init(ref: RawDataFileReference(data: data))
                    }
                }
                """,
                foundationSource: """
                    init(url: URL) throws {
                        try self.init(ref: SystemFileReference(url: url))
                    }
                """
                )
            }

            @Test("generic parameter on parent type")
            func expandsSyncInitializerWithGenericParameterOnType() {
                MacroTests.expectExpansion(
                    """
                    struct ParentType<F: FileReference> {
                        let file: F

                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(file: F) throws {
                            self.file = file
                        }
                    }
                    """,
                    expandedSource: """
                    struct ParentType<F: FileReference> {
                        let file: F
                        init(file: F) throws {
                            self.file = file
                        }

                        init(path: FilePath) throws where F == SystemFileReference {
                            try self.init(file: SystemFileReference(path: path))
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws where F == SystemFileReference {
                            try self.init(file: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        init(data: some Collection<UInt8>) throws where F == RawDataFileReference {
                            try self.init(file: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL) throws where F == SystemFileReference {
                            try self.init(file: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("generic parameter referenced in other generic parameter")
            func expandsSyncInitializerWithGenericParameterReferencedInOtherGenericParameter() {
                MacroTests.expectExpansion(
                """
                struct ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R, array: Array<R>) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                struct ParentType {
                    init<R: FileReference>(ref: R, array: Array<R>) throws {
                        print("Initialize something")
                    }

                    init(path: FilePath, array: Array<SystemFileReference>) throws {
                        try self.init(ref: SystemFileReference(path: path), array: array)
                    }

                    init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: Array<SystemFileReference>) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                    }

                    init(data: some Collection<UInt8>, array: Array<RawDataFileReference>) throws {
                        try self.init(ref: RawDataFileReference(data: data), array: array)
                    }
                }
                """,
                foundationSource: """
                    init(url: URL, array: Array<SystemFileReference>) throws {
                        try self.init(ref: SystemFileReference(url: url), array: array)
                    }
                """
                )
            }

            @Test("generic parameter referenced in array parameter")
            func expandsSyncInitializerWithGenericParameterReferencedInArrayParameter() {
                MacroTests.expectExpansion(
                """
                struct ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R, array: [R]) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                struct ParentType {
                    init<R: FileReference>(ref: R, array: [R]) throws {
                        print("Initialize something")
                    }

                    init(path: FilePath, array: [SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(path: path), array: array)
                    }

                    init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: [SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                    }

                    init(data: some Collection<UInt8>, array: [RawDataFileReference]) throws {
                        try self.init(ref: RawDataFileReference(data: data), array: array)
                    }
                }
                """,
                foundationSource: """
                    init(url: URL, array: [SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(url: url), array: array)
                    }
                """
                )
            }

            @Test("generic parameter referenced in dictionary parameter")
            func expandsSyncInitializerWithGenericParameterReferencedInDictionary() {
                MacroTests.expectExpansion(
                """
                struct ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R, dict: [String : R]) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                struct ParentType {
                    init<R: FileReference>(ref: R, dict: [String : R]) throws {
                        print("Initialize something")
                    }

                    init(path: FilePath, dict: [String : SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(path: path), dict: dict)
                    }

                    init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, dict: [String : SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), dict: dict)
                    }

                    init(data: some Collection<UInt8>, dict: [String : RawDataFileReference]) throws {
                        try self.init(ref: RawDataFileReference(data: data), dict: dict)
                    }
                }
                """,
                foundationSource: """
                    init(url: URL, dict: [String : SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(url: url), dict: dict)
                    }
                """
                )
            }

            @Test("generic parameter referenced in closure")
            func expandsSyncInitializerWithGenericParameterReferencedInClosure() {
                MacroTests.expectExpansion(
                """
                struct ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R, closure: (R) -> Void) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                struct ParentType {
                    init<R: FileReference>(ref: R, closure: (R) -> Void) throws {
                        print("Initialize something")
                    }

                    init(path: FilePath, closure: (SystemFileReference) -> Void) throws {
                        try self.init(ref: SystemFileReference(path: path), closure: closure)
                    }

                    init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, closure: (SystemFileReference) -> Void) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), closure: closure)
                    }

                    init(data: some Collection<UInt8>, closure: (RawDataFileReference) -> Void) throws {
                        try self.init(ref: RawDataFileReference(data: data), closure: closure)
                    }
                }
                """,
                foundationSource: """
                    init(url: URL, closure: (SystemFileReference) -> Void) throws {
                        try self.init(ref: SystemFileReference(url: url), closure: closure)
                    }
                """
                )
            }

            @Test("multiple generic parameters")
            func expandsSyncInitializerWithMultipleGenericParameters() {
                MacroTests.expectExpansion(
                """
                struct ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                struct ParentType {
                    init<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) throws {
                        print("Initialize something")
                    }

                    init<S: StringProtocol>(type: S.Type, path: FilePath) throws {
                        try self.init(type: type, ref: SystemFileReference(path: path))
                    }

                    init<S: StringProtocol>(type: S.Type, fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
                        try self.init(type: type, ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                    }

                    init<S: StringProtocol>(type: S.Type, data: some Collection<UInt8>) throws {
                        try self.init(type: type, ref: RawDataFileReference(data: data))
                    }
                }
                """,
                foundationSource: """
                    init<S: StringProtocol>(type: S.Type, url: URL) throws {
                        try self.init(type: type, ref: SystemFileReference(url: url))
                    }
                """
                )

                MacroTests.expectExpansion(
                """
                struct ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                struct ParentType {
                    init<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) throws {
                        print("Initialize something")
                    }

                    init<S: StringProtocol>(path: FilePath, type: S.Type) throws {
                        try self.init(ref: SystemFileReference(path: path), type: type)
                    }

                    init<S: StringProtocol>(fileDescriptor: FileDescriptor, closeWhenDone: Bool, type: S.Type) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), type: type)
                    }

                    init<S: StringProtocol>(data: some Collection<UInt8>, type: S.Type) throws {
                        try self.init(ref: RawDataFileReference(data: data), type: type)
                    }
                }
                """,
                foundationSource: """
                    init<S: StringProtocol>(url: URL, type: S.Type) throws {
                        try self.init(ref: SystemFileReference(url: url), type: type)
                    }
                """
                )
            }
        }
    }

    @Suite("Class initializer")
    struct ClassInitializer {
        @Suite("async")
        struct Async {
            @Test("some")
            func expandsAsyncInitializerWithSome() {
                MacroTests.expectExpansion(
                    """
                    class ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(ref: some FileReference) async throws {
                            print("initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    class ParentType {
                        init(ref: some FileReference) async throws {
                            print("initialize something")
                        }

                        convenience init(path: FilePath) async throws {
                            try await self.init(ref: SystemFileReference(path: path))
                        }

                        convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        convenience init(data: some Collection<UInt8>) async throws {
                            try await self.init(ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        convenience init(url: URL) async throws {
                            try await self.init(ref: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("any")
            func expandsAsyncInitializerWithAny() {
                MacroTests.expectExpansion(
                    """
                    class ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(ref: any FileReference) async throws {
                            print("initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    class ParentType {
                        init(ref: any FileReference) async throws {
                            print("initialize something")
                        }

                        convenience init(path: FilePath) async throws {
                            try await self.init(ref: SystemFileReference(path: path))
                        }

                        convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        convenience init(data: some Collection<UInt8>) async throws {
                            try await self.init(ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        convenience init(url: URL) async throws {
                            try await self.init(ref: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("generic parameter")
            func expandsAsyncInitializerWithGenericParameter() {
                MacroTests.expectExpansion(
                    """
                    class ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    class ParentType {
                        init<R: FileReference>(ref: R) async throws {
                            print("Initialize something")
                        }

                        convenience init(path: FilePath) async throws {
                            try await self.init(ref: SystemFileReference(path: path))
                        }

                        convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        convenience init(data: some Collection<UInt8>) async throws {
                            try await self.init(ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        convenience init(url: URL) async throws {
                            try await self.init(ref: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("generic parameter on parent type")
            func expandsAsyncInitializerWithGenericParameterOnType() {
                MacroTests.expectExpansion(
                    """
                    class ParentType<F: FileReference> {
                        let file: F

                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(file: F) async throws {
                            self.file = file
                        }
                    }
                    """,
                    expandedSource: """
                    class ParentType<F: FileReference> {
                        let file: F
                        init(file: F) async throws {
                            self.file = file
                        }

                        convenience init(path: FilePath) async throws where F == SystemFileReference {
                            try await self.init(file: SystemFileReference(path: path))
                        }

                        convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws where F == SystemFileReference {
                            try await self.init(file: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        convenience init(data: some Collection<UInt8>) async throws where F == RawDataFileReference {
                            try await self.init(file: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        convenience init(url: URL) async throws where F == SystemFileReference {
                            try await self.init(file: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("generic parameter referenced in other generic parameter")
            func expandsAsyncInitializerWithGenericParameterReferencedInOtherGenericParameter() {
                MacroTests.expectExpansion(
                    """
                    class ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R, array: Array<R>) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    class ParentType {
                        init<R: FileReference>(ref: R, array: Array<R>) async throws {
                            print("Initialize something")
                        }

                        convenience init(path: FilePath, array: Array<SystemFileReference>) async throws {
                            try await self.init(ref: SystemFileReference(path: path), array: array)
                        }

                        convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: Array<SystemFileReference>) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                        }

                        convenience init(data: some Collection<UInt8>, array: Array<RawDataFileReference>) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), array: array)
                        }
                    }
                    """,
                    foundationSource: """
                        convenience init(url: URL, array: Array<SystemFileReference>) async throws {
                            try await self.init(ref: SystemFileReference(url: url), array: array)
                        }
                    """
                )
            }

            @Test("generic parameter referenced in array parameter")
            func expandsAsyncInitializerWithGenericParameterReferencedInArrayParameter() {
                MacroTests.expectExpansion(
                    """
                    class ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R, array: [R]) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    class ParentType {
                        init<R: FileReference>(ref: R, array: [R]) async throws {
                            print("Initialize something")
                        }

                        convenience init(path: FilePath, array: [SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(path: path), array: array)
                        }

                        convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: [SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                        }

                        convenience init(data: some Collection<UInt8>, array: [RawDataFileReference]) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), array: array)
                        }
                    }
                    """,
                    foundationSource: """
                        convenience init(url: URL, array: [SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(url: url), array: array)
                        }
                    """
                )
            }

            @Test("generic parameter referenced in dictionary parameter")
            func expandsAsyncInitializerWithGenericParameterReferencedInDictionary() {
                MacroTests.expectExpansion(
                    """
                    class ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R, dict: [String : R]) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    class ParentType {
                        init<R: FileReference>(ref: R, dict: [String : R]) async throws {
                            print("Initialize something")
                        }

                        convenience init(path: FilePath, dict: [String : SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(path: path), dict: dict)
                        }

                        convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, dict: [String : SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), dict: dict)
                        }

                        convenience init(data: some Collection<UInt8>, dict: [String : RawDataFileReference]) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), dict: dict)
                        }
                    }
                    """,
                    foundationSource: """
                        convenience init(url: URL, dict: [String : SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(url: url), dict: dict)
                        }
                    """
                )
            }

            @Test("generic parameter referenced in closure")
            func expandsAsyncInitializerWithGenericParameterReferencedInClosure() {
                MacroTests.expectExpansion(
                    """
                    class ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R, closure: (R) -> Void) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    class ParentType {
                        init<R: FileReference>(ref: R, closure: (R) -> Void) async throws {
                            print("Initialize something")
                        }

                        convenience init(path: FilePath, closure: (SystemFileReference) -> Void) async throws {
                            try await self.init(ref: SystemFileReference(path: path), closure: closure)
                        }

                        convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, closure: (SystemFileReference) -> Void) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), closure: closure)
                        }

                        convenience init(data: some Collection<UInt8>, closure: (RawDataFileReference) -> Void) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), closure: closure)
                        }
                    }
                    """,
                    foundationSource: """
                        convenience init(url: URL, closure: (SystemFileReference) -> Void) async throws {
                            try await self.init(ref: SystemFileReference(url: url), closure: closure)
                        }
                    """
                )
            }

            @Test("multiple generic parameters")
            func expandsAsyncInitializerWithMultipleGenericParameters() {
                MacroTests.expectExpansion(
                    """
                    class ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    class ParentType {
                        init<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) async throws {
                            print("Initialize something")
                        }

                        convenience init<S: StringProtocol>(type: S.Type, path: FilePath) async throws {
                            try await self.init(type: type, ref: SystemFileReference(path: path))
                        }

                        convenience init<S: StringProtocol>(type: S.Type, fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws {
                            try await self.init(type: type, ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        convenience init<S: StringProtocol>(type: S.Type, data: some Collection<UInt8>) async throws {
                            try await self.init(type: type, ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        convenience init<S: StringProtocol>(type: S.Type, url: URL) async throws {
                            try await self.init(type: type, ref: SystemFileReference(url: url))
                        }
                    """
                )

                MacroTests.expectExpansion(
                    """
                    class ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    class ParentType {
                        init<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) async throws {
                            print("Initialize something")
                        }

                        convenience init<S: StringProtocol>(path: FilePath, type: S.Type) async throws {
                            try await self.init(ref: SystemFileReference(path: path), type: type)
                        }

                        convenience init<S: StringProtocol>(fileDescriptor: FileDescriptor, closeWhenDone: Bool, type: S.Type) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), type: type)
                        }

                        convenience init<S: StringProtocol>(data: some Collection<UInt8>, type: S.Type) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), type: type)
                        }
                    }
                    """,
                    foundationSource: """
                        convenience init<S: StringProtocol>(url: URL, type: S.Type) async throws {
                            try await self.init(ref: SystemFileReference(url: url), type: type)
                        }
                    """
                )
            }
        }

        @Suite("sync")
        struct Sync {
            @Test("some")
            func expandsSyncInitializerWithSome() {
                MacroTests.expectExpansion(
                    """
                    class ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(ref: some SyncFileReference) throws {
                            print("initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    class ParentType {
                        init(ref: some SyncFileReference) throws {
                            print("initialize something")
                        }

                        convenience init(path: FilePath) throws {
                            try self.init(ref: SystemFileReference(path: path))
                        }

                        convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
                            try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        convenience init(data: some Collection<UInt8>) throws {
                            try self.init(ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        convenience init(url: URL) throws {
                            try self.init(ref: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("any")
            func expandsSyncInitializerWithAny() {
                MacroTests.expectExpansion(
                """
                class ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init(ref: any SyncFileReference) throws {
                        print("initialize something")
                    }
                }
                """,
                expandedSource: """
                class ParentType {
                    init(ref: any SyncFileReference) throws {
                        print("initialize something")
                    }

                    convenience init(path: FilePath) throws {
                        try self.init(ref: SystemFileReference(path: path))
                    }

                    convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                    }

                    convenience init(data: some Collection<UInt8>) throws {
                        try self.init(ref: RawDataFileReference(data: data))
                    }
                }
                """,
                foundationSource: """
                    convenience init(url: URL) throws {
                        try self.init(ref: SystemFileReference(url: url))
                    }
                """
                )
            }

            @Test("generic parameter")
            func expandsSyncInitializerWithGenericParameter() {
                MacroTests.expectExpansion(
                """
                class ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                class ParentType {
                    init<R: FileReference>(ref: R) throws {
                        print("Initialize something")
                    }

                    convenience init(path: FilePath) throws {
                        try self.init(ref: SystemFileReference(path: path))
                    }

                    convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                    }

                    convenience init(data: some Collection<UInt8>) throws {
                        try self.init(ref: RawDataFileReference(data: data))
                    }
                }
                """,
                foundationSource: """
                    convenience init(url: URL) throws {
                        try self.init(ref: SystemFileReference(url: url))
                    }
                """
                )
            }

            @Test("generic parameter on parent type")
            func expandsSyncInitializerWithGenericParameterOnType() {
                MacroTests.expectExpansion(
                    """
                    class ParentType<F: FileReference> {
                        let file: F

                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(file: F) throws {
                            self.file = file
                        }
                    }
                    """,
                    expandedSource: """
                    class ParentType<F: FileReference> {
                        let file: F
                        init(file: F) throws {
                            self.file = file
                        }

                        convenience init(path: FilePath) throws where F == SystemFileReference {
                            try self.init(file: SystemFileReference(path: path))
                        }

                        convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws where F == SystemFileReference {
                            try self.init(file: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        convenience init(data: some Collection<UInt8>) throws where F == RawDataFileReference {
                            try self.init(file: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        convenience init(url: URL) throws where F == SystemFileReference {
                            try self.init(file: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("generic parameter referenced in other generic parameter")
            func expandsSyncInitializerWithGenericParameterReferencedInOtherGenericParameter() {
                MacroTests.expectExpansion(
                """
                class ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R, array: Array<R>) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                class ParentType {
                    init<R: FileReference>(ref: R, array: Array<R>) throws {
                        print("Initialize something")
                    }

                    convenience init(path: FilePath, array: Array<SystemFileReference>) throws {
                        try self.init(ref: SystemFileReference(path: path), array: array)
                    }

                    convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: Array<SystemFileReference>) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                    }

                    convenience init(data: some Collection<UInt8>, array: Array<RawDataFileReference>) throws {
                        try self.init(ref: RawDataFileReference(data: data), array: array)
                    }
                }
                """,
                foundationSource: """
                    convenience init(url: URL, array: Array<SystemFileReference>) throws {
                        try self.init(ref: SystemFileReference(url: url), array: array)
                    }
                """
                )
            }

            @Test("generic parameter referenced in array parameter")
            func expandsSyncInitializerWithGenericParameterReferencedInArrayParameter() {
                MacroTests.expectExpansion(
                """
                class ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R, array: [R]) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                class ParentType {
                    init<R: FileReference>(ref: R, array: [R]) throws {
                        print("Initialize something")
                    }

                    convenience init(path: FilePath, array: [SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(path: path), array: array)
                    }

                    convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: [SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                    }

                    convenience init(data: some Collection<UInt8>, array: [RawDataFileReference]) throws {
                        try self.init(ref: RawDataFileReference(data: data), array: array)
                    }
                }
                """,
                foundationSource: """
                    convenience init(url: URL, array: [SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(url: url), array: array)
                    }
                """
                )
            }

            @Test("generic parameter referenced in dictionary parameter")
            func expandsSyncInitializerWithGenericParameterReferencedInDictionary() {
                MacroTests.expectExpansion(
                """
                class ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R, dict: [String : R]) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                class ParentType {
                    init<R: FileReference>(ref: R, dict: [String : R]) throws {
                        print("Initialize something")
                    }

                    convenience init(path: FilePath, dict: [String : SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(path: path), dict: dict)
                    }

                    convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, dict: [String : SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), dict: dict)
                    }

                    convenience init(data: some Collection<UInt8>, dict: [String : RawDataFileReference]) throws {
                        try self.init(ref: RawDataFileReference(data: data), dict: dict)
                    }
                }
                """,
                foundationSource: """
                    convenience init(url: URL, dict: [String : SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(url: url), dict: dict)
                    }
                """
                )
            }

            @Test("generic parameter referenced in closure")
            func expandsSyncInitializerWithGenericParameterReferencedInClosure() {
                MacroTests.expectExpansion(
                """
                class ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R, closure: (R) -> Void) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                class ParentType {
                    init<R: FileReference>(ref: R, closure: (R) -> Void) throws {
                        print("Initialize something")
                    }

                    convenience init(path: FilePath, closure: (SystemFileReference) -> Void) throws {
                        try self.init(ref: SystemFileReference(path: path), closure: closure)
                    }

                    convenience init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, closure: (SystemFileReference) -> Void) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), closure: closure)
                    }

                    convenience init(data: some Collection<UInt8>, closure: (RawDataFileReference) -> Void) throws {
                        try self.init(ref: RawDataFileReference(data: data), closure: closure)
                    }
                }
                """,
                foundationSource: """
                    convenience init(url: URL, closure: (SystemFileReference) -> Void) throws {
                        try self.init(ref: SystemFileReference(url: url), closure: closure)
                    }
                """
                )
            }

            @Test("multiple generic parameters")
            func expandsSyncInitializerWithMultipleGenericParameters() {
                MacroTests.expectExpansion(
                """
                class ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                class ParentType {
                    init<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) throws {
                        print("Initialize something")
                    }

                    convenience init<S: StringProtocol>(type: S.Type, path: FilePath) throws {
                        try self.init(type: type, ref: SystemFileReference(path: path))
                    }

                    convenience init<S: StringProtocol>(type: S.Type, fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
                        try self.init(type: type, ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                    }

                    convenience init<S: StringProtocol>(type: S.Type, data: some Collection<UInt8>) throws {
                        try self.init(type: type, ref: RawDataFileReference(data: data))
                    }
                }
                """,
                foundationSource: """
                    convenience init<S: StringProtocol>(type: S.Type, url: URL) throws {
                        try self.init(type: type, ref: SystemFileReference(url: url))
                    }
                """
                )

                MacroTests.expectExpansion(
                """
                class ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                class ParentType {
                    init<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) throws {
                        print("Initialize something")
                    }

                    convenience init<S: StringProtocol>(path: FilePath, type: S.Type) throws {
                        try self.init(ref: SystemFileReference(path: path), type: type)
                    }

                    convenience init<S: StringProtocol>(fileDescriptor: FileDescriptor, closeWhenDone: Bool, type: S.Type) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), type: type)
                    }

                    convenience init<S: StringProtocol>(data: some Collection<UInt8>, type: S.Type) throws {
                        try self.init(ref: RawDataFileReference(data: data), type: type)
                    }
                }
                """,
                foundationSource: """
                    convenience init<S: StringProtocol>(url: URL, type: S.Type) throws {
                        try self.init(ref: SystemFileReference(url: url), type: type)
                    }
                """
                )
            }
        }
    }

    @Suite("Actor initializer")
    struct ActorInitializer {
        @Suite("async")
        struct Async {
            @Test("some")
            func expandsAsyncInitializerWithSome() {
                MacroTests.expectExpansion(
                    """
                    actor ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(ref: some FileReference) async throws {
                            print("initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    actor ParentType {
                        init(ref: some FileReference) async throws {
                            print("initialize something")
                        }

                        init(path: FilePath) async throws {
                            try await self.init(ref: SystemFileReference(path: path))
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }
                    
                        init(data: some Collection<UInt8>) async throws {
                            try await self.init(ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL) async throws {
                            try await self.init(ref: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("any")
            func expandsAsyncInitializerWithAny() {
                MacroTests.expectExpansion(
                    """
                    actor ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(ref: any FileReference) async throws {
                            print("initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    actor ParentType {
                        init(ref: any FileReference) async throws {
                            print("initialize something")
                        }

                        init(path: FilePath) async throws {
                            try await self.init(ref: SystemFileReference(path: path))
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        init(data: some Collection<UInt8>) async throws {
                            try await self.init(ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL) async throws {
                            try await self.init(ref: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("generic parameter")
            func expandsAsyncInitializerWithGenericParameter() {
                MacroTests.expectExpansion(
                    """
                    actor ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    actor ParentType {
                        init<R: FileReference>(ref: R) async throws {
                            print("Initialize something")
                        }

                        init(path: FilePath) async throws {
                            try await self.init(ref: SystemFileReference(path: path))
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        init(data: some Collection<UInt8>) async throws {
                            try await self.init(ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL) async throws {
                            try await self.init(ref: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("generic parameter on parent type")
            func expandsAsyncInitializerWithGenericParameterOnType() {
                MacroTests.expectExpansion(
                    """
                    actor ParentType<F: FileReference> {
                        let file: F

                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(file: F) async throws {
                            self.file = file
                        }
                    }
                    """,
                    expandedSource: """
                    actor ParentType<F: FileReference> {
                        let file: F
                        init(file: F) async throws {
                            self.file = file
                        }

                        init(path: FilePath) async throws where F == SystemFileReference {
                            try await self.init(file: SystemFileReference(path: path))
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws where F == SystemFileReference {
                            try await self.init(file: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        init(data: some Collection<UInt8>) async throws where F == RawDataFileReference {
                            try await self.init(file: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL) async throws where F == SystemFileReference {
                            try await self.init(file: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("generic parameter referenced in other generic parameter")
            func expandsAsyncInitializerWithGenericParameterReferencedInOtherGenericParameter() {
                MacroTests.expectExpansion(
                    """
                    actor ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R, array: Array<R>) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    actor ParentType {
                        init<R: FileReference>(ref: R, array: Array<R>) async throws {
                            print("Initialize something")
                        }

                        init(path: FilePath, array: Array<SystemFileReference>) async throws {
                            try await self.init(ref: SystemFileReference(path: path), array: array)
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: Array<SystemFileReference>) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                        }

                        init(data: some Collection<UInt8>, array: Array<RawDataFileReference>) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), array: array)
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL, array: Array<SystemFileReference>) async throws {
                            try await self.init(ref: SystemFileReference(url: url), array: array)
                        }
                    """
                )
            }

            @Test("generic parameter referenced in array parameter")
            func expandsAsyncInitializerWithGenericParameterReferencedInArrayParameter() {
                MacroTests.expectExpansion(
                    """
                    actor ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R, array: [R]) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    actor ParentType {
                        init<R: FileReference>(ref: R, array: [R]) async throws {
                            print("Initialize something")
                        }

                        init(path: FilePath, array: [SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(path: path), array: array)
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: [SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                        }

                        init(data: some Collection<UInt8>, array: [RawDataFileReference]) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), array: array)
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL, array: [SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(url: url), array: array)
                        }
                    """
                )
            }

            @Test("generic parameter referenced in dictionary parameter")
            func expandsAsyncInitializerWithGenericParameterReferencedInDictionary() {
                MacroTests.expectExpansion(
                    """
                    actor ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R, dict: [String : R]) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    actor ParentType {
                        init<R: FileReference>(ref: R, dict: [String : R]) async throws {
                            print("Initialize something")
                        }

                        init(path: FilePath, dict: [String : SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(path: path), dict: dict)
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, dict: [String : SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), dict: dict)
                        }

                        init(data: some Collection<UInt8>, dict: [String : RawDataFileReference]) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), dict: dict)
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL, dict: [String : SystemFileReference]) async throws {
                            try await self.init(ref: SystemFileReference(url: url), dict: dict)
                        }
                    """
                )
            }

            @Test("generic parameter referenced in closure")
            func expandsAsyncInitializerWithGenericParameterReferencedInClosure() {
                MacroTests.expectExpansion(
                    """
                    actor ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference>(ref: R, closure: (R) -> Void) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    actor ParentType {
                        init<R: FileReference>(ref: R, closure: (R) -> Void) async throws {
                            print("Initialize something")
                        }

                        init(path: FilePath, closure: (SystemFileReference) -> Void) async throws {
                            try await self.init(ref: SystemFileReference(path: path), closure: closure)
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, closure: (SystemFileReference) -> Void) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), closure: closure)
                        }

                        init(data: some Collection<UInt8>, closure: (RawDataFileReference) -> Void) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), closure: closure)
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL, closure: (SystemFileReference) -> Void) async throws {
                            try await self.init(ref: SystemFileReference(url: url), closure: closure)
                        }
                    """
                )
            }

            @Test("multiple generic parameters")
            func expandsAsyncInitializerWithMultipleGenericParameters() {
                MacroTests.expectExpansion(
                    """
                    actor ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    actor ParentType {
                        init<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) async throws {
                            print("Initialize something")
                        }

                        init<S: StringProtocol>(type: S.Type, path: FilePath) async throws {
                            try await self.init(type: type, ref: SystemFileReference(path: path))
                        }

                        init<S: StringProtocol>(type: S.Type, fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws {
                            try await self.init(type: type, ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        init<S: StringProtocol>(type: S.Type, data: some Collection<UInt8>) async throws {
                            try await self.init(type: type, ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init<S: StringProtocol>(type: S.Type, url: URL) async throws {
                            try await self.init(type: type, ref: SystemFileReference(url: url))
                        }
                    """
                )

                MacroTests.expectExpansion(
                    """
                    actor ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) async throws {
                            print("Initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    actor ParentType {
                        init<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) async throws {
                            print("Initialize something")
                        }

                        init<S: StringProtocol>(path: FilePath, type: S.Type) async throws {
                            try await self.init(ref: SystemFileReference(path: path), type: type)
                        }

                        init<S: StringProtocol>(fileDescriptor: FileDescriptor, closeWhenDone: Bool, type: S.Type) async throws {
                            try await self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), type: type)
                        }

                        init<S: StringProtocol>(data: some Collection<UInt8>, type: S.Type) async throws {
                            try await self.init(ref: RawDataFileReference(data: data), type: type)
                        }
                    }
                    """,
                    foundationSource: """
                        init<S: StringProtocol>(url: URL, type: S.Type) async throws {
                            try await self.init(ref: SystemFileReference(url: url), type: type)
                        }
                    """
                )
            }
        }

        @Suite("sync")
        struct Sync {
            @Test("some")
            func expandsSyncInitializerWithSome() {
                MacroTests.expectExpansion(
                    """
                    actor ParentType {
                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(ref: some SyncFileReference) throws {
                            print("initialize something")
                        }
                    }
                    """,
                    expandedSource: """
                    actor ParentType {
                        init(ref: some SyncFileReference) throws {
                            print("initialize something")
                        }

                        init(path: FilePath) throws {
                            try self.init(ref: SystemFileReference(path: path))
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
                            try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }
                    
                        init(data: some Collection<UInt8>) throws {
                            try self.init(ref: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL) throws {
                            try self.init(ref: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("any")
            func expandsSyncInitializerWithAny() {
                MacroTests.expectExpansion(
                """
                actor ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init(ref: any SyncFileReference) throws {
                        print("initialize something")
                    }
                }
                """,
                expandedSource: """
                actor ParentType {
                    init(ref: any SyncFileReference) throws {
                        print("initialize something")
                    }

                    init(path: FilePath) throws {
                        try self.init(ref: SystemFileReference(path: path))
                    }

                    init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                    }

                    init(data: some Collection<UInt8>) throws {
                        try self.init(ref: RawDataFileReference(data: data))
                    }
                }
                """,
                foundationSource: """
                    init(url: URL) throws {
                        try self.init(ref: SystemFileReference(url: url))
                    }
                """
                )
            }

            @Test("generic parameter")
            func expandsSyncInitializerWithGenericParameter() {
                MacroTests.expectExpansion(
                """
                actor ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                actor ParentType {
                    init<R: FileReference>(ref: R) throws {
                        print("Initialize something")
                    }

                    init(path: FilePath) throws {
                        try self.init(ref: SystemFileReference(path: path))
                    }

                    init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                    }

                    init(data: some Collection<UInt8>) throws {
                        try self.init(ref: RawDataFileReference(data: data))
                    }
                }
                """,
                foundationSource: """
                    init(url: URL) throws {
                        try self.init(ref: SystemFileReference(url: url))
                    }
                """
                )
            }

            @Test("generic parameter on parent type")
            func expandsSyncInitializerWithGenericParameterOnType() {
                MacroTests.expectExpansion(
                    """
                    actor ParentType<F: FileReference> {
                        let file: F

                        @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                        init(file: F) throws {
                            self.file = file
                        }
                    }
                    """,
                    expandedSource: """
                    actor ParentType<F: FileReference> {
                        let file: F
                        init(file: F) throws {
                            self.file = file
                        }

                        init(path: FilePath) throws where F == SystemFileReference {
                            try self.init(file: SystemFileReference(path: path))
                        }

                        init(fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws where F == SystemFileReference {
                            try self.init(file: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                        }

                        init(data: some Collection<UInt8>) throws where F == RawDataFileReference {
                            try self.init(file: RawDataFileReference(data: data))
                        }
                    }
                    """,
                    foundationSource: """
                        init(url: URL) throws where F == SystemFileReference {
                            try self.init(file: SystemFileReference(url: url))
                        }
                    """
                )
            }

            @Test("generic parameter referenced in other generic parameter")
            func expandsSyncInitializerWithGenericParameterReferencedInOtherGenericParameter() {
                MacroTests.expectExpansion(
                """
                actor ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R, array: Array<R>) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                actor ParentType {
                    init<R: FileReference>(ref: R, array: Array<R>) throws {
                        print("Initialize something")
                    }

                    init(path: FilePath, array: Array<SystemFileReference>) throws {
                        try self.init(ref: SystemFileReference(path: path), array: array)
                    }

                    init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: Array<SystemFileReference>) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                    }

                    init(data: some Collection<UInt8>, array: Array<RawDataFileReference>) throws {
                        try self.init(ref: RawDataFileReference(data: data), array: array)
                    }
                }
                """,
                foundationSource: """
                    init(url: URL, array: Array<SystemFileReference>) throws {
                        try self.init(ref: SystemFileReference(url: url), array: array)
                    }
                """
                )
            }

            @Test("generic parameter referenced in array parameter")
            func expandsSyncInitializerWithGenericParameterReferencedInArrayParameter() {
                MacroTests.expectExpansion(
                """
                actor ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R, array: [R]) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                actor ParentType {
                    init<R: FileReference>(ref: R, array: [R]) throws {
                        print("Initialize something")
                    }

                    init(path: FilePath, array: [SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(path: path), array: array)
                    }

                    init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, array: [SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), array: array)
                    }

                    init(data: some Collection<UInt8>, array: [RawDataFileReference]) throws {
                        try self.init(ref: RawDataFileReference(data: data), array: array)
                    }
                }
                """,
                foundationSource: """
                    init(url: URL, array: [SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(url: url), array: array)
                    }
                """
                )
            }

            @Test("generic parameter referenced in dictionary parameter")
            func expandsSyncInitializerWithGenericParameterReferencedInDictionary() {
                MacroTests.expectExpansion(
                """
                actor ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R, dict: [String : R]) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                actor ParentType {
                    init<R: FileReference>(ref: R, dict: [String : R]) throws {
                        print("Initialize something")
                    }

                    init(path: FilePath, dict: [String : SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(path: path), dict: dict)
                    }

                    init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, dict: [String : SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), dict: dict)
                    }

                    init(data: some Collection<UInt8>, dict: [String : RawDataFileReference]) throws {
                        try self.init(ref: RawDataFileReference(data: data), dict: dict)
                    }
                }
                """,
                foundationSource: """
                    init(url: URL, dict: [String : SystemFileReference]) throws {
                        try self.init(ref: SystemFileReference(url: url), dict: dict)
                    }
                """
                )
            }

            @Test("generic parameter referenced in closure")
            func expandsSyncInitializerWithGenericParameterReferencedInClosure() {
                MacroTests.expectExpansion(
                """
                actor ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference>(ref: R, closure: (R) -> Void) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                actor ParentType {
                    init<R: FileReference>(ref: R, closure: (R) -> Void) throws {
                        print("Initialize something")
                    }

                    init(path: FilePath, closure: (SystemFileReference) -> Void) throws {
                        try self.init(ref: SystemFileReference(path: path), closure: closure)
                    }

                    init(fileDescriptor: FileDescriptor, closeWhenDone: Bool, closure: (SystemFileReference) -> Void) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), closure: closure)
                    }

                    init(data: some Collection<UInt8>, closure: (RawDataFileReference) -> Void) throws {
                        try self.init(ref: RawDataFileReference(data: data), closure: closure)
                    }
                }
                """,
                foundationSource: """
                    init(url: URL, closure: (SystemFileReference) -> Void) throws {
                        try self.init(ref: SystemFileReference(url: url), closure: closure)
                    }
                """
                )
            }

            @Test("multiple generic parameters")
            func expandsSyncInitializerWithMultipleGenericParameters() {
                MacroTests.expectExpansion(
                """
                actor ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                actor ParentType {
                    init<S: StringProtocol, R: FileReference>(type: S.Type, ref: R) throws {
                        print("Initialize something")
                    }

                    init<S: StringProtocol>(type: S.Type, path: FilePath) throws {
                        try self.init(type: type, ref: SystemFileReference(path: path))
                    }

                    init<S: StringProtocol>(type: S.Type, fileDescriptor: FileDescriptor, closeWhenDone: Bool) throws {
                        try self.init(type: type, ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
                    }

                    init<S: StringProtocol>(type: S.Type, data: some Collection<UInt8>) throws {
                        try self.init(type: type, ref: RawDataFileReference(data: data))
                    }
                }
                """,
                foundationSource: """
                    init<S: StringProtocol>(type: S.Type, url: URL) throws {
                        try self.init(type: type, ref: SystemFileReference(url: url))
                    }
                """
                )

                MacroTests.expectExpansion(
                """
                actor ParentType {
                    @FileReference([.filePath, .fileDescriptor, .rawData, .url])
                    init<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) throws {
                        print("Initialize something")
                    }
                }
                """,
                expandedSource: """
                actor ParentType {
                    init<R: FileReference, S: StringProtocol>(ref: R, type: S.Type) throws {
                        print("Initialize something")
                    }

                    init<S: StringProtocol>(path: FilePath, type: S.Type) throws {
                        try self.init(ref: SystemFileReference(path: path), type: type)
                    }

                    init<S: StringProtocol>(fileDescriptor: FileDescriptor, closeWhenDone: Bool, type: S.Type) throws {
                        try self.init(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone), type: type)
                    }

                    init<S: StringProtocol>(data: some Collection<UInt8>, type: S.Type) throws {
                        try self.init(ref: RawDataFileReference(data: data), type: type)
                    }
                }
                """,
                foundationSource: """
                    init<S: StringProtocol>(url: URL, type: S.Type) throws {
                        try self.init(ref: SystemFileReference(url: url), type: type)
                    }
                """
                )
            }
        }
    }

    @Test("default generators")
    func defaultGenerators() {
        MacroTests.expectExpansion(
            """
            @FileReference
            func foo(ref: some FileReference) async throws -> String {
                return "Foo"
            }
            """,
            expandedSource: """
            func foo(ref: some FileReference) async throws -> String {
                return "Foo"
            }

            func foo(path: FilePath) async throws -> String {
                try await foo(ref: SystemFileReference(path: path))
            }

            func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws -> String {
                try await foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
            }
            """,
            foundationSource: """
            func foo(url: URL) async throws -> String {
                try await foo(ref: SystemFileReference(url: url))
            }
            """
        )
    }

    @Test("path generator")
    func filePathGenerator() {
        MacroTests.expectExpansion(
            """
            @FileReference(.filePath)
            func foo(ref: some FileReference) async throws -> String {
                return "Foo"
            }
            """,
            expandedSource: """
            func foo(ref: some FileReference) async throws -> String {
                return "Foo"
            }

            func foo(path: FilePath) async throws -> String {
                try await foo(ref: SystemFileReference(path: path))
            }
            """,
            foundationSource: ""
        )
    }

    @Test("file descriptor generator")
    func fileDescriptorGenerator() {
        MacroTests.expectExpansion(
            """
            @FileReference(.fileDescriptor)
            func foo(ref: some FileReference) async throws -> String {
                return "Foo"
            }
            """,
            expandedSource: """
            func foo(ref: some FileReference) async throws -> String {
                return "Foo"
            }

            func foo(fileDescriptor: FileDescriptor, closeWhenDone: Bool) async throws -> String {
                try await foo(ref: SystemFileReference(fileDescriptor: fileDescriptor, closeWhenDone: closeWhenDone))
            }
            """,
            foundationSource: ""
        )
    }

    @Test("raw data generator")
    func rawDataGenerator() {
        MacroTests.expectExpansion(
            """
            @FileReference(.rawData)
            func foo(ref: some FileReference) async throws -> String {
                return "Foo"
            }
            """,
            expandedSource: """
            func foo(ref: some FileReference) async throws -> String {
                return "Foo"
            }

            func foo(data: some Collection<UInt8>) async throws -> String {
                try await foo(ref: RawDataFileReference(data: data))
            }
            """,
            foundationSource: ""
        )
    }

#if Foundation
    @Test("url generator")
    func urlGenerator() {
        MacroTests.expectExpansion(
            """
            @FileReference(.url)
            func foo(ref: some FileReference) async throws -> String {
                return "Foo"
            }
            """,
            expandedSource: """
            func foo(ref: some FileReference) async throws -> String {
                return "Foo"
            }

            func foo(url: URL) async throws -> String {
                try await foo(ref: SystemFileReference(url: url))
            }
            """,
            foundationSource: ""
        )
    }
#endif

    @Test
    func failsWhenAttachedToNonFunctionOrInitializer() async throws {
        MacroTests.expectError(
            """
            @FileReference
            var foo: String
            """,
            errorName: "notAFunctionOrInitializer"
            )

            MacroTests.expectError(
            """
            @FileReference
            class Foo {}
            """,
            errorName: "notAFunctionOrInitializer"
        )
    }

    @Test
    func failsWhenNoFileRefArgument() async throws {
        MacroTests.expectError(
            """
            @FileReference
            func foo() throws
            """,
            errorName: "noFileReferenceArgument"
        )

        MacroTests.expectError(
            """
            @FileReference
            func foo(path: FilePath) throws
            """,
            errorName: "noFileReferenceArgument"
        )
    }

    @Test
    func failsWhenFunctionNotThrowing() async throws {
        MacroTests.expectError(
            """
            @FileReference
            func foo(ref: some FileReference) async {
                print("do something")
            }
            """,
            errorName: "functionNotThrowing"
        )
    }

    private static func expectExpansion(
        _ originalSource: String,
        expandedSource: String,
        foundationSource: String,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
#if Foundation
        let fullSource = if try! /^class|struct|actor/.firstMatch(in: expandedSource) != nil {
            "\(expandedSource.dropLast())\n\(foundationSource)\n}"
        } else {
            "\(expandedSource)\n\n\(foundationSource)"
        }
#else
        let fullSource = expandedSource
#endif

        assertMacroExpansion(
            originalSource,
            expandedSource: fullSource,
            macros: self.macros,
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )
    }

    private static func expectError(
        _ originalSource: String,
        errorName: String,
        errorLine: Int = 1,
        errorColumn: Int = 1,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertMacroExpansion(
            originalSource,
            expandedSource: String(originalSource[originalSource.firstIndex(of: "\n")!...]),
            diagnostics: [DiagnosticSpec(message: errorName, line: errorLine, column: errorColumn)],
            macros: self.macros,
            fileID: fileID,
            file: file,
            line: line,
            column: column
        )
    }
}

#endif
