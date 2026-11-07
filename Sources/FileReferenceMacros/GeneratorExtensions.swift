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
        node.arguments?.as(LabeledExprListSyntax.self)?.compactMap {
            guard let functionCall = $0.expression.as(FunctionCallExprSyntax.self),
                  let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
                  case .identifier(let name) = memberAccess.declName.baseName.tokenKind else {
                return nil
            }

            let arg = functionCall.arguments.first?.expression.as(StringLiteralExprSyntax.self)
            let label = arg?.segments.first?.as(StringSegmentSyntax.self)?.content.text

            return Self(name: name, label: label)
        }
    }

    init?(name: String, label: String?) {
        switch name {
        case "filePath": self = .filePath(label)
        case "fileDescriptor": self = .fileDescriptor(label)
        case "rawData": self = .rawData(label)
#if Foundation
        case "url": self = .url(label)
#endif
        default: return nil
        }
    }

    var label: String? {
        switch self {
        case .filePath(let label): label
        case .fileDescriptor(let label): label
        case .rawData(let label): label
        case .url(let label): label
        }
    }

    var parameterName: String {
        switch self {
        case .filePath: "path"
        case .fileDescriptor: "fileDescriptor"
        case .rawData: "data"
        case .url: "url"
        }
    }

    var fileReferenceTypeName: String {
        switch self {
        case .filePath, .fileDescriptor: "SystemFileReference"
        case .rawData: "RawDataFileReference"
        case .url: "SystemFileReference"
        }
    }

    var typeName: String {
        switch self {
        case .filePath: "FilePath"
        case .fileDescriptor: "FileDescriptor"
        case .rawData: "some Collection<UInt8>"
        case .url: "URL"
        }
    }

    var additionalParams: [FunctionParameterSyntax] {
        switch self {
        case .filePath, .rawData: []
        case .fileDescriptor: [self.param(type: "Bool", name: "closeWhenDone")]
        case .url: []
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
