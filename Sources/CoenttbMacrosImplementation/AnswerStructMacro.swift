//
//  File.swift
//  coenttb-ui
//
//  Created by Coen ten Thije Boonkkamp on 12/11/2024.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct AnswerStructMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.onlyApplicableToStruct
        }
        
        guard let initializer = findInitializer(in: structDecl) else {
            throw MacroError.noInitializer
        }
        
        let parameters = try extractParameters(from: initializer)
        
        let answersStruct = try generateAnswersStruct(parameters: parameters)
        let convertingInitializer = try generateConvertingInitializer(parameters: parameters)
        
        return [answersStruct, convertingInitializer]
    }
    
    private struct Parameter {
        let name: String
        let type: String
    }
    
    private static func findInitializer(in structDecl: StructDeclSyntax) -> InitializerDeclSyntax? {
        for member in structDecl.memberBlock.members {
            if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
                return initDecl
            }
        }
        return nil
    }

    
    private static func extractParameters(from initializer: InitializerDeclSyntax) throws -> [Parameter] {
        var parameters: [Parameter] = []
        
        for parameter in initializer.signature.parameterClause.parameters {
            if let optionalType = parameter.type.as(OptionalTypeSyntax.self),
               let baseType = optionalType.wrappedType.as(IdentifierTypeSyntax.self) {
                parameters.append(Parameter(
                    name: parameter.firstName.text,
                    type: baseType.name.text
                ))
            } else if let baseType = parameter.type.as(IdentifierTypeSyntax.self) {
                parameters.append(Parameter(
                    name: parameter.firstName.text,
                    type: baseType.name.text
                ))
            } else {
                throw MacroError.invalidParameterType(parameter.firstName.text)
            }
        }
        
        return parameters
    }
    
    private static func generateAnswersStruct(parameters: [Parameter]) throws -> DeclSyntax {
        let properties = parameters
            .map { "public var \($0.name): Answer<\($0.type)> = .unanswered" }
            .joined(separator: "\n    ")
            
        let initParameters = parameters
            .map { "\($0.name): Answer<\($0.type)> = .unanswered" }
            .joined(separator: ",\n        ")
            
        let initAssignments = parameters
            .map { "self.\($0.name) = \($0.name)" }
            .joined(separator: "\n        ")
        
        return """
        @GenerateAnswerCases
        public struct Answers: Codable, Hashable, Sendable {
            \(raw: properties)
            
            public init(
                \(raw: initParameters)
            ) {
                \(raw: initAssignments)
            }
        }
        """
    }
    
    private static func generateConvertingInitializer(parameters: [Parameter]) throws -> DeclSyntax {
        let valueExtractions = parameters
            .map { parameter in
                    """
                    let \(parameter.name): \(parameter.type)? = {
                        switch answers.\(parameter.name) {
                        case .unanswered:
                            return nil
                        case .answered(.dontKnow):
                            return nil
                        case .answered(.answered(let value)):
                            return value
                        }
                    }()
                    """
            }
            .joined(separator: "\n        ")
        
        let initParameters = parameters
            .map { "\($0.name): \($0.name)" }
            .joined(separator: ",\n            ")
        
        return """
            public init?(answers: Answers) {
                \(raw: valueExtractions)
                
                self.init(
                    \(raw: initParameters)
                )
            }
            """
    }
    
}

enum MacroError: Error, CustomStringConvertible {
    case onlyApplicableToStruct
    case noInitializer
    case invalidParameterType(String)
    
    var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@GenerateAnswerStruct can only be applied to structs"
        case .noInitializer:
            return "Struct must have an initializer"
        case .invalidParameterType(let name):
            return "Parameter '\(name)' must be of type Bool, String, Int, etc."
        }
    }
}
