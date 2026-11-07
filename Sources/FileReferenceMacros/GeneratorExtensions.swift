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

        let functionCalls: [FunctionCallExprSyntax]? = if let array = expr.as(ArrayExprSyntax.self) {
            array.elements.compactMap { $0.expression.as(FunctionCallExprSyntax.self) }
        } else if let decl = expr.as(FunctionCallExprSyntax.self) {
            [decl]
        } else {
            nil
        }

        return functionCalls?.compactMap { functionCall -> Generator? in
            guard let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
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
#if Foundation
        case .url(let label): label
#endif
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
