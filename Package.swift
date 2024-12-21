// swift-tools-version:6.0

@preconcurrency import PackageDescription
import CompilerPluginSupport

extension String {
    static let utils: Self = "CoenttbUtils"
    static let arrayBuilder: Self = "ArrayBuilder"
    static let boundedCache: Self = "BoundedCache"
    static let rateLimiter: Self = "RateLimiter"
}

extension Target.Dependency {
    static var arrayBuilder: Self { .target(name: .arrayBuilder) }
    static var boundedCache: Self { .target(name: .boundedCache) }
    static var rateLimiter: Self { .target(name: .rateLimiter) }
}

extension Target.Dependency {
    static var dependencies: Self { .product(name: "Dependencies", package: "swift-dependencies") }
}

extension [Target.Dependency] {
    static var shared: Self {
        [.dependencies]
    }
}

extension [Package.Dependency] {
    static var `default`: Self {
        [
            .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.3.5")
        ]
    }
}

struct CustomTarget {
    let name: String
    var library: Bool = true
    var dependencies: [Target.Dependency] = []
}

let package = Package.utils(
    targets: [
        .init(
            name: .utils,
            library: true,
            dependencies: [
                .arrayBuilder,
            ]
        ),
        .init(
            name: .arrayBuilder,
            library: true,
            dependencies: []
        ),
        .init(
            name: .boundedCache,
            library: true,
            dependencies: []
        ),
        .init(
            name: .rateLimiter,
            library: true,
            dependencies: [
                .boundedCache
            ]
        ),
    ]
)

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
            products: .products(targets),
            dependencies: .default,
            targets: .targets(targets)
        )
    }
}

extension [Product] {
    static func products(_ targets: [CustomTarget]) -> [Product] {
        targets.map { target in
            target.library
            ? .library(name: target.name, targets: ["\(target.name)"])
            : nil
        }.compactMap { $0 }
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
        }
    }
}
