//
//  File.swift
//  coenttb-ui
//
//  Created by Coen ten Thije Boonkkamp on 11/11/2024.
//

import Foundation
import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftCompilerPlugin

// MARK: - Main Macro Implementation
public struct AnswerCasesMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw AnswerCasesMacroError.onlyApplicableToStruct
        }
        
        let properties = try extractProperties(from: structDecl, context: context)
        let enumDecl = try generateAnswerCasesEnum(properties: properties)
        
        return [enumDecl]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            fatalError()
        }
        
        let name = structDecl.name.text
        let conformanceExtension = try ExtensionDeclSyntax("extension \(raw: name): HasAnswerCases") {
            // Implement any required members or properties for HasAnswerCases here if needed
        }
        
        return [conformanceExtension]
    }
    
    // MARK: - Property Extraction
    private static func extractProperties(
        from structDecl: StructDeclSyntax,
        context: some MacroExpansionContext
    ) throws -> [AnswerProperty] {
        let properties = structDecl.memberBlock.members.compactMap { member in
            AnswerProperty(from: member)
        }
        
        guard !properties.isEmpty else {
            throw AnswerCasesMacroError.noAnswerProperties
        }
        
        return properties
    }
    
    // MARK: - Code Generation
    private static func generateAnswerCasesEnum(properties: [AnswerProperty]) throws -> DeclSyntax {
        let enumCases = properties
            .map { "case \($0.name)" }
            .joined(separator: "\n    ")
        
        let descriptionCases = properties
            .map { "case .\($0.name): return \"\($0.name)\"" }
            .joined(separator: "\n        ")
        
        let valueTypeCases = properties
            .map { "case .\($0.name): return \($0.valueType).self" }
            .joined(separator: "\n        ")
        
        return """
        public enum AnswerCase: Hashable, CaseIterable, CustomStringConvertible {
            \(raw: enumCases)
            
            public var description: String {
                switch self {
                \(raw: descriptionCases)
                }
            }
            
            public var valueType: Any.Type {
                switch self {
                \(raw: valueTypeCases)
                }
            }
        }
        """
    }
}

// MARK: - Error Types
enum AnswerCasesMacroError: Error, CustomStringConvertible {
    case onlyApplicableToStruct
    case noAnswerProperties
    case invalidPropertyType(name: String)
    
    var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@GenerateAnswerCases can only be applied to structs"
        case .noAnswerProperties:
            return "Struct must contain at least one Answer<T> property"
        case .invalidPropertyType(let name):
            return "Property '\(name)' must be of type Answer<T>"
        }
    }
}

// MARK: - Property Information
struct AnswerProperty {
    let name: String
    let type: String
    let valueType: String
    
    init?(from member: MemberBlockItemSyntax) {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
              let typeAnnotation = binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self),
              typeAnnotation.name.text == "Answer",
              let genericArg = typeAnnotation.genericArgumentClause?.arguments.first?.argument else {
            return nil
        }
        
        self.name = identifier.identifier.text
        self.type = typeAnnotation.description
        self.valueType = genericArg.description
    }
}


// MARK: - Compiler Plugin Registration
@main
struct AnswerCasesMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AnswerCasesMacro.self,
        AnswerStructMacro.self
    ]
}
