// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "loco",
	platforms: [
	  .iOS(.v9),
	  .macOS(.v10_11)
	],
    products: [
      .executable(name: "loco", targets: ["loco"])
    ],
    dependencies: [
	  .package(name: "Funswift", url: "https://github.com/konrad1977/funswift", .branch("main"))
    ],
    targets: [
      .target(
        name: "loco",
        dependencies: ["Funswift"]),
    ]
)
