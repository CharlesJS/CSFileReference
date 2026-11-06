//
//  CompilerPlugin.swift
//  CSFileReference
//
//  Created by Charles Srstka on 10/31/26.
//

#if Macros

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FileReferenceMacroCompilerPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [FileReferenceMacro.self]
}
#else
@main
struct Dummy {
    static func main() {}
}
#endif
