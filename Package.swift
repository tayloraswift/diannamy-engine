// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "main",
    products:
    [
        .executable(name: "atmospheric-scattering", targets: ["AtmosphericScattering"]),
        .executable(name: "main", targets: ["Main"])
    ],
    dependencies:
    [
        .package(url: "https://github.com/tayloraswift/swift-png", exact: "4.4.0"),
        .package(url: "https://github.com/tayloraswift/swift-noise", exact: "1.1.0"),

        .package(url: "https://github.com/kylef/Commander", exact: "0.9.1"),
    ],
    targets:
    [
        .systemLibrary(name: "FreeType", path: "sources/c/freetype", pkgConfig: "freetype2"),
        .systemLibrary(name: "HarfBuzz", path: "sources/c/harfbuzz", pkgConfig: "harfbuzz"),
        .target(name: "GLFW", path: "sources/c/glfw"),

        .target(name: "Error" , dependencies: [], path: "sources/error"),
        .target(name: "File" ,  dependencies: ["Error"], path: "sources/file"),

        .target(
            name: "AtmosphericScattering",
            dependencies: [
                "File",
                .product(name: "PNG", package: "swift-png"),
                .product(name: "Commander", package: "Commander"),
            ],
            path: "sources/atmospheric-scattering"
        ),
        .target(
            name: "Main",
            dependencies: [
                "Error",
                "File",
                "FreeType",
                "HarfBuzz",
                "GLFW",
                .product(name: "PNG", package: "swift-png"),
                .product(name: "Noise", package: "swift-noise"),
            ],
            path: "sources/main"
        ),
    ],
    swiftLanguageModes: [.v5],
)
