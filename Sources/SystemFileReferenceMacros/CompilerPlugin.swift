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
struct SystemFileReferenceMacroCompilerPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [SystemFileReferenceMacro.self]
}
#else
@main
struct Dummy {
    static func main() {}
}
#endif
