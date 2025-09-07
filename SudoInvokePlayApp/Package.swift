// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SudoInvokePlayApp",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SudoInvokePlayApp", targets: ["SudoInvokePlayApp"]),
    ],
    dependencies: [
        .package(url: "git@github.com:Kamaalio/KamaalSwift.git", .upToNextMajor(from: "3.3.0")),
    ],
    targets: [
        .target(
            name: "SudoInvokePlayApp",
            dependencies: [
                .product(name: "KamaalUtils", package: "KamaalSwift")
            ]
        ),
    ]
)
