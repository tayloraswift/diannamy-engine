// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "polysphere",
    products: 
    [
        .executable(name: "generator", targets: ["generator"])
    ],
    dependencies: 
    [
        .package(url: "https://github.com/kelvin13/swiftxml", .branch("master")), 
    ],
    targets: 
    [
        .target(name: "generator" , dependencies: ["XML"], path: "sources/generator"), 
        .target(name: "GLFW", path: "sources/GLFW"), 
        .target(name: "polysphere", dependencies: ["GLFW"], path: "sources/polysphere"),
    ]
)
