//
//  MacroGenerators.swift
//  CSFileReference
//
//  Created by Charles Srstka on 11/5/26.
//

#if Macros

public enum Generator: Sendable {
    case filePath
    case fileDescriptor
    case rawData
#if Foundation
    case url
#endif
}

#endif
