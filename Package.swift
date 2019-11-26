// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "polysphere",
    products: 
    [
//        .executable(name: "generator", targets: ["generator"])
    ],
    dependencies: 
    [
        .package(url: "https://github.com/kelvin13/png",   .exact("3.0.0")), 
        .package(url: "https://github.com/kelvin13/noise", .branch("master")), 
//        .package(url: "https://github.com/kelvin13/swiftxml", .branch("master")), 
    ],
    targets: 
    [
//        .target(name: "generator" , dependencies: ["XML"], path: "sources/generator"), 
        .systemLibrary(name: "FreeType", path: "sources/c/freetype", pkgConfig: "freetype2"), 
        .systemLibrary(name: "HarfBuzz", path: "sources/c/harfbuzz", pkgConfig: "harfbuzz"), 
        .target(name: "GLFW", path: "sources/c/glfw"), 
        .target(name: "polysphere", dependencies: ["FreeType", "HarfBuzz", "GLFW", "PNG", "Noise"], path: "sources/polysphere"),
    ]
)
