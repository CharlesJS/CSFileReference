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
    var keyword: TokenSyntax { get set }
    var signature: FunctionSignatureSyntax { get set }
}

extension FunctionDeclSyntax: FuncOrInit {
    var keyword: TokenSyntax {
        get { self.funcKeyword }
        set { self.funcKeyword = newValue }
    }
}

extension InitializerDeclSyntax: FuncOrInit {
    var keyword: TokenSyntax {
        get { self.initKeyword }
        set { self.initKeyword = newValue }
    }
}

private final class WhitespaceStripper: SyntaxRewriter {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        token
            .with(\.leadingTrivia, Trivia(pieces: token.leadingTrivia.filter { !$0.isWhitespace }))
            .with(\.trailingTrivia, Trivia(pieces: token.trailingTrivia.filter { !$0.isWhitespace }))
    }
}

private final class AsyncToSync: SyntaxRewriter {
    private static let mapping = ["getData" : "syncGetData", "getBytes": "syncGetBytes"]
    private let forceSync: Bool
    private(set) var cannotConvert = false

    init(forceSync: Bool) {
        self.forceSync = forceSync
        super.init()
    }

    override func visit(_ awaitSyntax: AwaitExprSyntax) -> ExprSyntax {
        if let function = awaitSyntax.expression.as(FunctionCallExprSyntax.self) {
            if var memberAccess = function.calledExpression.as(MemberAccessExprSyntax.self),
               let mapped = Self.mapping[memberAccess.declName.baseName.text] {
                memberAccess.declName.baseName = .identifier(mapped)
                return ExprSyntax(function.with(\.calledExpression, ExprSyntax(memberAccess)))
            } else if self.forceSync {
                return ExprSyntax(function)
            } else {
                self.cannotConvert = true
            }
        }

        return ExprSyntax(awaitSyntax)
    }
}

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
            try self.expansion(function: function, node: node, context: context)
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
        let forceSync = node.arguments?.as(LabeledExprListSyntax.self)?.contains { (expr: LabeledExprSyntax) -> Bool in
            return (
                expr.label?.text == "forceSync" &&
                expr.expression.as(BooleanLiteralExprSyntax.self)?.literal.tokenKind ~= .keyword(.true)
            )
        } == true

        guard let (argIndex, contextType) = self.fileRefIndex(function: function, context: context) else {
            throw Error.noFileReferenceArgument
        }

        let isClass = context.lexicalContext.first?.is(ClassDeclSyntax.self) == true

        guard function.signature.effectSpecifiers?.throwsClause?.throwsSpecifier.tokenKind ~= .keyword(.throws) else {
            throw Error.functionNotThrowing
        }

        if let syncFunction = self.syncVersion(of: function, forceSync: forceSync) {
            return try [
                DeclSyntax(syncFunction.with(\.attributes, []))
            ] + self.expansion(function: syncFunction, node: node, context: context)
        }

        return generators.map {
            self.makeFunc(from: function, generator: $0, argIndex: argIndex, contextType: contextType, isClass: isClass)
        }
    }

    private static func syncVersion<F: FuncOrInit>(of function: F, forceSync: Bool) -> F? {
        guard function.signature.effectSpecifiers?.asyncSpecifier?.tokenKind ~= .keyword(SwiftSyntax.Keyword.async),
              let syncBody = self.syncBody(for: function, forceSync: forceSync) else {
            return nil
        }

        var syncFunc = function.with(\.body, syncBody)

        syncFunc.keyword.leadingTrivia = .spaces(2)
        syncFunc.signature.effectSpecifiers?.asyncSpecifier = nil

        for index in syncFunc.signature.parameterClause.parameters.indices {
            self.replaceType(
                "FileReference",
                in: &syncFunc.signature.parameterClause.parameters[index].type,
                with: "SyncFileReference"
            )
        }

        if var returnClause = syncFunc.signature.returnClause {
            self.replaceType("FileReference", in: &returnClause.type, with: "SyncFileReference")
            syncFunc.signature.returnClause = returnClause
        }

        if var genericParameterClause = syncFunc.genericParameterClause {
            for index in genericParameterClause.parameters.indices {
                if var type = genericParameterClause.parameters[index].inheritedType {
                    self.replaceType("FileReference", in: &type, with: "SyncFileReference")
                    genericParameterClause.parameters[index].inheritedType = type
                }
            }
            syncFunc.genericParameterClause = genericParameterClause
        }

        if var genericWhereClause = syncFunc.genericWhereClause {
            for index in genericWhereClause.requirements.indices {
                switch genericWhereClause.requirements[index].requirement {
                case .sameTypeRequirement(var requirement):
                    switch requirement.rightType {
                    case .type(var type):
                        self.replaceType("FileReference", in: &type, with: "SyncFileReference")
                        requirement.rightType = .type(type)
                    case .expr:
                        break
                    }
                    genericWhereClause.requirements[index].requirement = .sameTypeRequirement(requirement)
                case .conformanceRequirement(var requirement):
                    self.replaceType("FileReference", in: &requirement.rightType, with: "SyncFileReference")
                    genericWhereClause.requirements[index].requirement = .conformanceRequirement(requirement)
                case .layoutRequirement:
                    break
                }
            }

            syncFunc.genericWhereClause = genericWhereClause
        }

        return syncFunc
    }

    private static func syncBody(for function: some FuncOrInit, forceSync: Bool) -> CodeBlockSyntax? {
        guard let body = function.body else { return nil }

        let rewriter = AsyncToSync(forceSync: forceSync)
        let syncBody = rewriter.visit(body)

        if rewriter.cannotConvert { return nil }

        return WhitespaceStripper().visit(syncBody)
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
        generator: Generator,
        argIndex: FunctionParameterListSyntax.Index,
        contextType: String?,
        isClass: Bool
    ) -> DeclSyntax {
        if isClass,
           var initDecl = funcOrInit.as(InitializerDeclSyntax.self),
           !initDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.convenience) }) {
            initDecl.modifiers.insert(DeclModifierSyntax(name: .keyword(.convenience)), at: initDecl.modifiers.startIndex)
            initDecl.initKeyword.leadingTrivia = []
            return self.makeFunc(
                from: initDecl,
                generator: generator,
                argIndex: argIndex,
                contextType: contextType,
                isClass: isClass
            )
        }

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
        } else if var id = type.as(SomeOrAnyTypeSyntax.self) {
            self.replaceType(oldType, in: &id.constraint, with: newType)
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
