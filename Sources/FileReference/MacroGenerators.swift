//
//  MacroGenerators.swift
//  CSFileReference
//
//  Created by Charles Srstka on 11/5/26.
//

#if Macros

public enum Generator: Sendable {
    case filePath(String?)
    case fileDescriptor(String?)
    case rawData(String?)
#if Foundation
    case url(String?)
#endif
}

#endif
