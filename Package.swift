// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "main",
    products: 
    [
        .executable(name: "atmospheric-scattering", targets: ["AtmosphericScattering"]), 
        .executable(name: "main", targets: ["Main"])
//        .executable(name: "generator", targets: ["generator"])
    ],
    dependencies: 
    [
        .package(url: "https://github.com/kelvin13/png",   .exact("3.0.0")), 
        .package(url: "https://github.com/kelvin13/noise", .branch("master")), 
        // .package(url: "https://github.com/kelvin13/swiftxml", .branch("master")), 
        
        .package(url: "https://github.com/kylef/Commander",   .exact("0.9.1")), 
    ],
    targets: 
    [
//        .target(name: "generator" , dependencies: ["XML"], path: "sources/generator"), 
        .systemLibrary(name: "FreeType", path: "sources/c/freetype", pkgConfig: "freetype2"), 
        .systemLibrary(name: "HarfBuzz", path: "sources/c/harfbuzz", pkgConfig: "harfbuzz"), 
        .target(name: "GLFW", path: "sources/c/glfw"), 
        
        .target(name: "Error" , dependencies: [], path: "sources/error"), 
        .target(name: "File" ,  dependencies: ["Error"], path: "sources/file"), 
        
        .target(name: "AtmosphericScattering" , dependencies: ["File", "PNG", "Commander"], path: "sources/atmospheric-scattering"), 
        .target(name: "Main", dependencies: ["Error", "File", "FreeType", "HarfBuzz", "GLFW", "PNG", "Noise"], path: "sources/main"),
    ]
)
