//
//  Macros.swift
//  CSFileReference
//
//  Created by Charles Srstka on 11/3/26.
//

#if Macros

@attached(peer, names: overloaded)
public macro FileReference(_ generators: [Generator] = []) = #externalMacro(
    module: "FileReferenceMacros",
    type: "FileReferenceMacro"
)

#endif

