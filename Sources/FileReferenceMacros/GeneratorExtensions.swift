//
//  GeneratorExtensions.swift
//  CSFileReference
//
//  Created by Charles Srstka on 11/5/26.
//

#if Macros

import SwiftSyntax

extension Generator {
    static func parse(node: SwiftSyntax.AttributeSyntax) -> [Generator]? {
        guard let expr = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression else { return nil}

        let memberAccess: [MemberAccessExprSyntax]? = if let array = expr.as(ArrayExprSyntax.self) {
            array.elements.compactMap { $0.expression.as(MemberAccessExprSyntax.self) }
        } else if let decl = expr.as(MemberAccessExprSyntax.self) {
            [decl]
        } else {
            nil
        }

        return memberAccess?.compactMap {
            switch $0.declName.baseName.tokenKind {
            case .identifier(let name):
                return Self(name: name)
            default:
                return nil
            }
        }
    }

    init?(name: String) {
        switch name {
        case "filePath": self = .filePath
        case "fileDescriptor": self = .fileDescriptor
        case "rawData": self = .rawData
#if Foundation
        case "url": self = .url
#endif
        default: return nil
        }
    }

    var parameterName: String {
        switch self {
        case .filePath: "path"
        case .fileDescriptor: "fileDescriptor"
        case .rawData: "data"
#if Foundation
        case .url: "url"
#endif
        }
    }

    var fileReferenceTypeName: String {
        switch self {
        case .filePath, .fileDescriptor: "SystemFileReference"
        case .rawData: "RawDataFileReference"
#if Foundation
        case .url: "SystemFileReference"
#endif
        }
    }

    var typeName: String {
        switch self {
        case .filePath: "FilePath"
        case .fileDescriptor: "FileDescriptor"
        case .rawData: "some Collection<UInt8>"
#if Foundation
        case .url: "URL"
#endif
        }
    }

    var additionalParams: [FunctionParameterSyntax] {
        switch self {
        case .filePath, .rawData: []
        case .fileDescriptor: [self.param(type: "Bool", name: "closeWhenDone")]
#if Foundation
        case .url: []
#endif
        }
    }

    private func param(type: String, name: String, default: String? = nil) -> FunctionParameterSyntax {
        let defaultValue = `default`.map {
            InitializerClauseSyntax(equal: .equalToken(), value: ExprSyntax(stringLiteral: $0))
        }

        return FunctionParameterSyntax(
            attributes: AttributeListSyntax(),
            modifiers: DeclModifierListSyntax(),
            firstName: TokenSyntax.identifier(name),
            colon: TokenSyntax.colonToken(trailingTrivia: .space),
            type: TypeSyntax(IdentifierTypeSyntax(name: .identifier(type))),
            defaultValue: defaultValue
        )
    }

}

#endif
