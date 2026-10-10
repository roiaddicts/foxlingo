// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "FoxlingoCore", platforms: [.macOS(.v13), .iOS(.v17)], products: [.library(name: "FoxlingoCore", targets: ["FoxlingoCore"])], targets: [.target(name: "FoxlingoCore", path: "Foxlingo/Core"), .testTarget(name: "FoxlingoCoreTests", dependencies: ["FoxlingoCore"], path: "FoxlingoTests", resources: [.copy("Fixtures/goltexto-2026-10-09-oracle.json")])])
