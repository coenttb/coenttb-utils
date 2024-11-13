//
//  File.swift
//  coenttb-ui
//
//  Created by Coen ten Thije Boonkkamp on 11/11/2024.
//

@attached(
    member,
    names: named(AnswerCase), named(HasAnswerCases)
)
@attached(
    extension,
    names: named(type),
    conformances: HasAnswerCases
)
public macro GenerateAnswerCases() = #externalMacro(
    module: "CoenttbMacrosImplementation",
    type: "AnswerCasesMacro"
)

public protocol HasAnswerCases {
    associatedtype AnswerCase: CaseIterable
}


// Macro declaration
@attached(
    member,
    names: named(Answers), named(init(answers:))
)
public macro GenerateAnswerStruct() = #externalMacro(
    module: "CoenttbMacrosImplementation",
    type: "AnswerStructMacro"
)
