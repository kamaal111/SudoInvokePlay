// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SudoInvokePlayApp",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "SudoInvokePlayApp", targets: ["SudoInvokePlayApp"]),
    ],
    targets: [
        .target(name: "SudoInvokePlayApp"),
    ]
)
