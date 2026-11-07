//
//  FileReferenceMacros.swift
//  CSFileReference
//
//  Created by Charles Srstka on 10/26/26.
//

#if Macros

import SwiftSyntax
import SwiftSyntaxMacros

private protocol FuncOrInit:
    DeclSyntaxProtocol, WithAttributesSyntax, WithGenericParametersSyntax, WithOptionalCodeBlockSyntax {
    var signature: FunctionSignatureSyntax { get set }
}

extension FunctionDeclSyntax: FuncOrInit {}
extension InitializerDeclSyntax: FuncOrInit {}

public struct FileReferenceMacro: PeerMacro {
    public enum Error: Swift.Error {
        case notAFunctionOrInitializer
        case noFileReferenceArgument
        case functionNotThrowing
    }

#if Foundation
    static let defaultGenerators: [Generator] = [.filePath(nil), .fileDescriptor(nil), .url(nil)]
#else
    static let defaultGenerators: [Generator] = [.filePath(nil), .fileDescriptor(nil)]
#endif

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [DeclSyntax] {
        if let function = declaration.as(FunctionDeclSyntax.self) {
            try self.expansion(function: function, node: node, context: context)
        } else if let function = declaration.as(InitializerDeclSyntax.self) {
            if context.lexicalContext.first?.is(ClassDeclSyntax.self) == true,
               !function.modifiers.contains(where: { $0.name == .keyword(.convenience) }) {
                try self.expansion(
                    function: function
                        .with(\.initKeyword.leadingTrivia, [])
                        .with(\.modifiers, function.modifiers + [
                            DeclModifierSyntax(name: .keyword(.convenience).with(\.trailingTrivia, .spaces(1)))
                        ]),
                    node: node,
                    context: context
                )
            } else {
                try self.expansion(function: function, node: node, context: context)
            }
        } else {
            throw Error.notAFunctionOrInitializer
        }
    }

    private static func expansion(
        function: some FuncOrInit,
        node: SwiftSyntax.AttributeSyntax,
        context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let generators = Generator.parse(node: node) ?? Self.defaultGenerators

        guard let (argIndex, contextType) = self.fileRefIndex(function: function, context: context) else {
            throw Error.noFileReferenceArgument
        }

        guard function.signature.effectSpecifiers?.throwsClause?.throwsSpecifier.tokenKind ~= .keyword(.throws) else {
            throw Error.functionNotThrowing
        }

        return generators.map {
            self.makeFunc(from: function, argIndex: argIndex, contextType: contextType, generator: $0)
        }
    }

    private static func fileRefIndex(
        function: some FuncOrInit,
        context: some SwiftSyntaxMacros.MacroExpansionContext
    ) -> (FunctionParameterListSyntax.Index, String?)? {
        let baseTypes = ["FileReference", "SyncFileReference"]

        var genericParams: [any WithGenericParametersSyntax] = [function]

        if let params = function.genericParameterClause?.parameters {
            genericParams += params.compactMap { $0.asProtocol((any WithGenericParametersSyntax).self) }
        }

        let types = baseTypes + genericParams.flatMap {
            $0.genericParameterClause?.parameters.compactMap { param in
                self.typeFromGenericParam(param, baseTypes: baseTypes)
            } ?? []
        }

        let contextTypes = context.lexicalContext.flatMap {
            $0.asProtocol((any WithGenericParametersSyntax).self)?.genericParameterClause?.parameters.compactMap { param in
                self.typeFromGenericParam(param, baseTypes: baseTypes)
            } ?? []
        }

        let params = function.signature.parameterClause.parameters

        for eachIndex in params.indices {
            let param = params[eachIndex]

            let type: String
            if let id = param.type.as(SomeOrAnyTypeSyntax.self)?.constraint.as(IdentifierTypeSyntax.self) {
                type = id.name.text
            } else if let id = param.type.as(IdentifierTypeSyntax.self) {
                type = id.name.text
            } else {
                continue
            }

            if types.contains(type) {
                return (eachIndex, nil)
            }

            if contextTypes.contains(type) {
                return (eachIndex, type)
            }
        }

        return nil
    }

    private static func typeFromGenericParam(_ param: GenericParameterSyntax, baseTypes: [String]) -> String? {
        guard let inheritedType = param.inheritedType?.as(IdentifierTypeSyntax.self)?.name.text else {
            return nil
        }

        return baseTypes.contains(inheritedType) ? param.name.text : nil
    }

    private static func makeFunc(
        from funcOrInit: some FuncOrInit,
        argIndex: FunctionParameterListSyntax.Index,
        contextType: String?,
        generator: Generator
    ) -> DeclSyntax {
        let sig = funcOrInit.signature
        let isAsync = sig.effectSpecifiers?.asyncSpecifier?.tokenKind ~= .keyword(SwiftSyntax.Keyword.async)

        let params = sig.parameterClause.parameters
        let additionalParams = generator.additionalParams
        let arg = params[argIndex]
        let newTypeIdentifier = IdentifierTypeSyntax(name: .identifier(generator.typeName))

        let label = generator.label
        let paramName = generator.parameterName
        let firstName = TokenSyntax.identifier(label ?? paramName)
        let secondName = (label != nil && label != paramName) ? TokenSyntax.identifier(paramName) : nil

        let newArg = arg
            .with(\.firstName, firstName)
            .with(\.secondName, secondName)
            .with(\.type, TypeSyntax(newTypeIdentifier))
        var newParams = params.with(\.[argIndex], newArg)
        for (offset, eachParam) in additionalParams.enumerated() {
            newParams.insert(eachParam, at: newParams.index(argIndex, offsetBy: offset + 1))
        }

        for index in newParams.indices {
            newParams[index].trailingComma = if newParams.index(after: index) == newParams.endIndex {
                nil
            } else {
                .commaToken()
            }
        }

        let fileRefTypeName = generator.fileReferenceTypeName
        let lastAdditionalIndex = newParams.index(argIndex, offsetBy: additionalParams.count)

        let callParams: [String] = zip(newParams.indices, newParams).compactMap { index, param in
            let refParams = ([param] + additionalParams).map {
                "\($0.secondName ?? $0.firstName): \($0.secondName ?? $0.firstName)"
            }.joined(separator: ",")

            return if index == argIndex {
                "\(params[index].firstName): \(fileRefTypeName)(\(refParams))"
            } else if index < argIndex || index > lastAdditionalIndex {
                "\(param.firstName): \(param.secondName ?? param.firstName)"
            } else {
                nil
            }
        }

        let name = (funcOrInit as? FunctionDeclSyntax)?.name.text ?? "self.init"

        var call = "\(name)(\(callParams.joined(separator: ", ")))"

        if isAsync {
            call = "await \(call)"
        }

        let newBody = """
        {
            try \(call)
        }
        """

        var returnClause = funcOrInit.signature.returnClause

        if let genericType = arg.type.as(IdentifierTypeSyntax.self)?.name.text {
            for eachIndex in newParams.indices {
                self.replaceType(genericType, in: &newParams[eachIndex].type, with: fileRefTypeName)
            }

            if var unwrappedReturnClause = returnClause {
                self.replaceType(genericType, in: &unwrappedReturnClause.type, with: fileRefTypeName)
                returnClause = unwrappedReturnClause
            }
        }

        let newFunction = funcOrInit
            .with(\.signature.parameterClause.parameters, newParams)
            .with(\.signature.returnClause, returnClause)
            .with(\.body, .init(stringLiteral: newBody))
            .with(\.attributes, [])
            .with(\.genericParameterClause, self.adjustGenericParameterClause(funcOrInit: funcOrInit, argIndex: argIndex))
            .with(\.genericWhereClause, self.adjustGenericWhereClause(
                funcOrInit: funcOrInit,
                contextType: contextType,
                fileRefTypeName: fileRefTypeName
            ))

        return DeclSyntax(newFunction)
    }

    private static func replaceType(_ oldType: String, in type: inout TypeSyntax, with newType: String) {
        if var id = type.as(IdentifierTypeSyntax.self) {
            if id.name.text == oldType {
                id.name = TokenSyntax(stringLiteral: newType)
            } else if var genericClause = id.genericArgumentClause {
                for eachIndex in genericClause.arguments.indices {
                    if case .type(var genericType) = genericClause.arguments[eachIndex].argument {
                        self.replaceType(oldType, in: &genericType, with: newType)
                        genericClause.arguments[eachIndex].argument = .type(genericType)
                    }
                }

                id.genericArgumentClause = genericClause
            }

            type = TypeSyntax(id)
        } else if var function = type.as(FunctionTypeSyntax.self) {
            for eachIndex in function.parameters.indices {
                self.replaceType(oldType, in: &function.parameters[eachIndex].type, with: newType)
            }

            type = TypeSyntax(function)
        }

        if var array = type.as(ArrayTypeSyntax.self) {
            self.replaceType(oldType, in: &array.element, with: newType)
            type = TypeSyntax(array)
        }

        if var dict = type.as(DictionaryTypeSyntax.self) {
            self.replaceType(oldType, in: &dict.key, with: newType)
            self.replaceType(oldType, in: &dict.value, with: newType)
            type = TypeSyntax(dict)
        }
    }

    private static func adjustGenericParameterClause(
        funcOrInit: some FuncOrInit,
        argIndex: FunctionParameterListSyntax.Index
    ) -> GenericParameterClauseSyntax? {
        guard let generic = funcOrInit.genericParameterClause else { return nil }
        let params = funcOrInit.signature.parameterClause.parameters

        guard let type = params[argIndex].type.as(IdentifierTypeSyntax.self)?.name.text else { return nil }

        var newGenericParams = generic.parameters.filter { $0.name.text != type }

        if newGenericParams.count == 0 {
            return nil
        }

        newGenericParams[newGenericParams.index(before: newGenericParams.endIndex)].trailingComma = nil

        return generic.with(\.parameters, newGenericParams)
    }

    private static func adjustGenericWhereClause(
        funcOrInit: some FuncOrInit,
        contextType: String?,
        fileRefTypeName: String
    ) -> GenericWhereClauseSyntax? {
        guard let contextType else { return funcOrInit.genericWhereClause }

        let requirement = GenericRequirementSyntax.Requirement.sameTypeRequirement(
            SameTypeRequirementSyntax(
                leftType: .type(TypeSyntax(IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: contextType)))),
                equal: .binaryOperator("=="),
                rightType: .type(TypeSyntax(IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: fileRefTypeName))))
            )
        )

        let requirementSyntax = GenericRequirementSyntax(requirement: requirement)

        if let existingWhereClause = funcOrInit.genericWhereClause {
            var newRequirements = existingWhereClause.requirements
            if !newRequirements.isEmpty {
                newRequirements[newRequirements.index(before: newRequirements.endIndex)].trailingComma = .commaToken()
            }

            newRequirements.append(requirementSyntax)

            return existingWhereClause.with(\.requirements, newRequirements)
        } else {
            return GenericWhereClauseSyntax(requirements: [requirementSyntax])
        }
    }
}

#endif
