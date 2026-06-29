// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MLKitTranslatePackage",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "MLKitTranslate",
            targets: [
                "MLKitTranslate",
                "SSZipArchive",
                "MLKitNaturalLanguage",
                "MLKitXenoCommon",
                "MLKitVision",
                "MLKitCommon",
                "GoogleToolboxForMac",
                "Common"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/google/promises.git", exact: "2.4.0"),
        .package(url: "https://github.com/google/GoogleDataTransport.git", exact: "10.1.0"),
        .package(url: "https://github.com/google/GoogleUtilities.git", exact: "8.1.0"),
        .package(url: "https://github.com/google/gtm-session-fetcher.git", exact: "5.3.0"),
        .package(url: "https://github.com/firebase/nanopb.git", exact: "2.30910.0")
    ],
    targets: [
        .binaryTarget(
            name: "MLKitCommon",
            url: "https://github.com/d-date/google-mlkit-swiftpm/releases/download/9.0.0-1/MLKitCommon.xcframework.zip",
            checksum: "0c3523adc6248b5fd7e71c5af1c3e028a2ffcd20ca6add03283e20a09740f43f"
        ),
        .binaryTarget(
            name: "GoogleToolboxForMac",
            url: "https://github.com/d-date/google-mlkit-swiftpm/releases/download/9.0.0-1/GoogleToolboxForMac.xcframework.zip",
            checksum: "c095707fd64bad2f36cd9bcc86251de6aab7197d5b35112f3cdf40c6c94a6b4b"
        ),
        .binaryTarget(
            name: "MLKitTranslate",
            url: "https://github.com/d-date/google-mlkit-swiftpm/releases/download/9.0.0-1/MLKitTranslate.xcframework.zip",
            checksum: "b08ce5354133185c5fc4f0e64dfda1e437c23f815734b40c08832ea8db4bcf11"
        ),
        .binaryTarget(
            name: "MLKitXenoCommon",
            url: "https://github.com/d-date/google-mlkit-swiftpm/releases/download/9.0.0-1/MLKitXenoCommon.xcframework.zip",
            checksum: "34ee8e96f9aba5e1d9394935c3db2e255534b2bf45c883c38a011637b7e08653"
        ),
        .binaryTarget(
            name: "MLKitNaturalLanguage",
            url: "https://github.com/d-date/google-mlkit-swiftpm/releases/download/9.0.0-1/MLKitNaturalLanguage.xcframework.zip",
            checksum: "55da788e46e3e2aa3e409da5a50db01c292a67ca84199039f81a46e80397d026"
        ),
        .binaryTarget(
            name: "MLKitVision",
            url: "https://github.com/d-date/google-mlkit-swiftpm/releases/download/9.0.0-1/MLKitVision.xcframework.zip",
            checksum: "b26f8c96d1e12515b990fca0b2237d60363d7bddc925d5ec61d7ee7d8b5e83c3"
        ),
        .binaryTarget(
            name: "SSZipArchive",
            url: "https://github.com/d-date/google-mlkit-swiftpm/releases/download/9.0.0-1/SSZipArchive.xcframework.zip",
            checksum: "5b179e6e8df6ef5d5b530e7d35e5e57503388db336a8050eca8e517e308a78be"
        ),
        .target(
            name: "Common",
            dependencies: [
                "MLKitCommon",
                "GoogleToolboxForMac",
                .product(name: "GULAppDelegateSwizzler", package: "GoogleUtilities"),
                .product(name: "GULEnvironment", package: "GoogleUtilities"),
                .product(name: "GULLogger", package: "GoogleUtilities"),
                .product(name: "GULMethodSwizzler", package: "GoogleUtilities"),
                .product(name: "GULNSData", package: "GoogleUtilities"),
                .product(name: "GULNetwork", package: "GoogleUtilities"),
                .product(name: "GULReachability", package: "GoogleUtilities"),
                .product(name: "GULUserDefaults", package: "GoogleUtilities"),
                .product(name: "GTMSessionFetcher", package: "gtm-session-fetcher"),
                .product(name: "GoogleDataTransport", package: "GoogleDataTransport"),
                .product(name: "nanopb", package: "nanopb"),
                .product(name: "FBLPromises", package: "promises")
            ],
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedFramework("CoreMedia")
            ]
        )
    ]
)
