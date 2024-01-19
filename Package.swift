// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyAppArch",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftyAppArch",
            targets: ["SwiftyAppArch"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.45.2"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/tristanhimmelman/ObjectMapper.git", from: "4.2.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.6.0"),
//        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.4"),
        .package(url: "https://github.com/Mioke/RxRealm.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftyAppArch",
            dependencies: [
                .product(name: "RealmSwift", package: "realm-swift"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "ObjectMapper", package: "ObjectMapper"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxRealm", package: "RxRealm"),
            ],
            path: "./SwiftyArchitecture/Base",
            exclude: ["Persistance", "Tests"]),
//        .testTarget(
//            name: "SwiftyAppArchTests",
//            dependencies: ["SwiftyAppArch"]),
    ],
    swiftLanguageVersions: [.v5]
)
