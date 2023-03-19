// swift-tools-version:5.7

import PackageDescription

let package = Package(
  name: "loco",
  platforms: [
    .macOS(.v10_14)
  ],
  products: [
    .executable(name: "loco", targets: ["loco"])
  ],
  dependencies: [
    .package(url: "https://github.com/konrad1977/funswift", branch: "main"),
  ],
  targets: [
    .executableTarget(
      name: "loco",
      dependencies: [
        .product(name: "Funswift", package: "funswift")
      ]),
    .testTarget(
      name: "LocoTests",
      dependencies: ["loco"]
    )
  ]
)
