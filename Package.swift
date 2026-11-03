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
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.0/CardSessions.xcframework.zip",
            checksum: "2585e89bb054c8f8d03d52129ecd3462081601030a826dd0207a3534e90dd9a9"
        ),
        .binaryTarget(
            name: "Card",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.0/Card.xcframework.zip",
            checksum: "16adf57e8e0f00d7f37311f87eed1d6a702655dcfe2912a460fa1a735c71bd5e"
        ),
        .binaryTarget(
            name: "CardProvisioningSessions",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.0/CardProvisioningSessions.xcframework.zip",
            checksum: "4f49791d43b2f652646c8d727196c27c00fdfe9ca4f7475222db4290a57ef2de"
        ),
        .binaryTarget(
            name: "CardProvisioning",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.0/CardProvisioning.xcframework.zip",
            checksum: "9c2c16ac7a55e1dc96cc5732b47a074e7fe0f10ff4c1ce47ba7acb1049ac3e44"
        ),
        .binaryTarget(
            name: "CardProvisioningExtension",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.0/CardProvisioningExtension.xcframework.zip",
            checksum: "9e8921f38e105cf905073a9c3ace1a5c79b7ed341cb3b58fc63dabac81eb669d"
        ),
        .binaryTarget(
            name: "IssuingCore",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.0/IssuingCore.xcframework.zip",
            checksum: "53c251a081567b0d944ecdde5f69a5bbfeee2a2c36509ee55ade2019095757ae"
        ),
        .binaryTarget(
            name: "IssuingCommon",
            url: "https://github.com/Adyen/adyen-issuing-ios/releases/download/1.0.0/IssuingCommon.xcframework.zip",
            checksum: "885b06da3b91d6c39a3d6452c6b488aa3cb0e0db0fdb4e18490eb73bd26bf0f5"
        )
    ]
)
