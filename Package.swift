// swift-tools-version:6.0

@preconcurrency import PackageDescription
import CompilerPluginSupport

extension String {
    static let utils: Self = "CoenttbUtils"
    static let arrayBuilder: Self = "ArrayBuilder"
    static let coenttbMacros: Self = "CoenttbMacros"
    static let coenttbMacrosImplementation: Self = "CoenttbMacrosImplementation"
}

extension Target.Dependency {
    static var arrayBuilder: Self { .target(name: .arrayBuilder) }
}



extension Target.Dependency {
    static var dependencies: Self { .product(name: "Dependencies", package: "swift-dependencies") }
    static var coenttbMacros: Self { .target(name: .coenttbMacros) }
}

extension [Target.Dependency] {
    static var shared: Self {
        [.dependencies]
    }
}

extension [Package.Dependency] {
    static var `default`: Self {
        [
            .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.3.5"),
            .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"601.0.0-prerelease"),
        ]
    }
}

struct CustomTarget {
    let name: String
    var library: Bool = true
    var dependencies: [Target.Dependency] = []
}

extension Package {
    static func utils(targets: [CustomTarget]) -> Package {
        return PackageDescription.Package(
            name: "coenttb-utils",
            platforms: [
                .iOS(.v13),
                .macOS(.v10_15),
                .tvOS(.v13),
                .watchOS(.v6),
            ],
            products: [
                .library(name: .utils, targets: [.utils]),
                .library(name: .arrayBuilder, targets: [.arrayBuilder]),
                .library(name: .coenttbMacros, targets: [.coenttbMacros])
            ],
            dependencies: .default,
            targets: .targets(targets)
        )
    }
}

extension [Target] {
    static func targets(_ targets: [CustomTarget]) -> [Target] {
        targets.flatMap { target in
            [
                Target.target(
                    name: target.name,
                    dependencies: .shared + target.dependencies
                ),
                Target.testTarget(
                    name: "\(target.name) Tests",
                    dependencies: [.init(stringLiteral: target.name)]
                )
            ]
        } + [
            Target.macro(
                name: .coenttbMacrosImplementation,
                dependencies: [
                    .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                    .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                ]
            ),
            Target.target(
                name: .coenttbMacros,
                dependencies: [
                    .target(name: .coenttbMacrosImplementation)
                ]
            )
        ]
    }
}

let package = Package.utils(
    targets: [
        .init(
            name: .utils,
            library: true,
            dependencies: [
                .arrayBuilder,
                .coenttbMacros
            ]
        ),
        .init(
            name: .arrayBuilder,
            library: true,
            dependencies: []
        ),
    ]
)
