// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AdyenIssuing",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "Card",                      targets: ["CardLib"]),
        .library(name: "CardSessions",             targets: ["CardSessionsLib"]),
        .library(name: "CardProvisioningSessions", targets: ["CardProvisioningSessionsLib"]),
        .library(name: "CardProvisioning",          targets: ["CardProvisioningLib"]),
        .library(name: "CardProvisioningExtension", targets: ["CardProvisioningExtensionLib"]),
        .library(name: "IssuingCommon",             targets: ["IssuingCommon"])
    ],
    targets: [
        .target(
            name: "CardLib",
            dependencies: ["Card"],
            path: "Sources/CardLib"
        ),
        .target(
            name: "CardSessionsLib",
            dependencies: ["CardSessions", "Card", "IssuingCore", "IssuingCommon"],
            path: "Sources/CardSessionsLib"
        ),
        .target(
            name: "CardProvisioningSessionsLib",
            dependencies: ["CardProvisioningSessions", "CardProvisioning", "CardProvisioningExtension", "IssuingCore", "IssuingCommon"],
            path: "Sources/CardProvisioningSessionsLib"
        ),
        .target(
            name: "CardProvisioningLib",
            dependencies: ["CardProvisioning", "IssuingCommon"],
            path: "Sources/CardProvisioningLib"
        ),
        .target(
            name: "CardProvisioningExtensionLib",
            dependencies: ["CardProvisioningExtension", "IssuingCommon"],
            path: "Sources/CardProvisioningExtensionLib"
        ),
        .binaryTarget(
            name: "CardSessions",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.2/CardSessions.xcframework.zip",
            checksum: "553885aea13338c744153cdf3ea79affd7834d976bb57b28fb2e08a653abec07"
        ),
        .binaryTarget(
            name: "Card",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.2/Card.xcframework.zip",
            checksum: "5eaf4219d369c8790423dff22e830c6a0a7f51d2b07d59d6e0f97be3bf3f9351"
        ),
        .binaryTarget(
            name: "CardProvisioningSessions",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.2/CardProvisioningSessions.xcframework.zip",
            checksum: "f4b92b1e1205c323fd30a5ec77d13178bc0e78a92226fca01e85c08675388da2"
        ),
        .binaryTarget(
            name: "CardProvisioning",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.2/CardProvisioning.xcframework.zip",
            checksum: "9e7666df615b0fdcfd6d3e184af3003da8b643797ee7cffcb3c7b3d7badbf372"
        ),
        .binaryTarget(
            name: "CardProvisioningExtension",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.2/CardProvisioningExtension.xcframework.zip",
            checksum: "adc31aebeb694ba94c1f00c9e38e042764ab0972d3d342adfc462dffeccefde7"
        ),
        .binaryTarget(
            name: "IssuingCore",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.2/IssuingCore.xcframework.zip",
            checksum: "df57af4a637792ef254ef18e3d2c273c8a72d387a8da5db9dc448eea7b666a2e"
        ),
        .binaryTarget(
            name: "IssuingCommon",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.2/IssuingCommon.xcframework.zip",
            checksum: "a96c58fe2c0614caecb64d28f89bbc081a4d2cbf74382923afbc98f4675af1fa"
        )
    ]
)
