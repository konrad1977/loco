// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Loco",
  platforms: [
	.macOS(.v10_11)
  ],
  products: [
    .executable(name: "loco", targets: ["Loco"])
  ],
  dependencies: [
	.package(name: "Funswift", url: "https://github.com/konrad1977/funswift", .branch("main"))
  ],
  targets: [
    .executableTarget(
      name: "Loco",
      dependencies: ["Funswift"]),
    .testTarget(
      name: "LocoTests",
      dependencies: ["Loco"]
    )
  ]
)
