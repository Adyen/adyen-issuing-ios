# Adyen Issuing SDK for iOS

[![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue)](https://developer.apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://swift.org)

The Adyen Issuing SDK enables iOS apps to integrate with Adyen's card issuing platform. It provides end-to-end encrypted card detail retrieval, PIN management, and Apple Wallet provisioning, all without sensitive data ever touching your server.

## Features

- **Card reveal** — securely display PAN, CVC, and expiry date in your app
- **PIN reveal & change** — let cardholders view or update their PIN
- **Apple Wallet provisioning** — add cards to Apple Pay from within your app
- **Wallet Extensions** — support in-app provisioning and Issuer Extensions for the Apple Wallet app

## Modules

| Module | Description |
|---|---|
| `CardSessions` | Card reveal (PAN, CVC, expiry), PIN reveal, and PIN change |
| `CardProvisioningSessions` | Apple Wallet provisioning sessions and Wallet Extension handlers |
| `IssuingCommon` | Shared types (`TokenProviding`, `SessionEnvironment`, `SessionToken`, `ErrorContext`) |

> **Note:** `CardProvisioning` and `CardProvisioningExtension` are legacy modules. New integrations should use `CardProvisioningSessions`.

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 16+
- An [Adyen Issuing](https://www.adyen.com/issuing) integration on your backend
- An app certificate issued by Adyen (`.der` format)
- App Attest entitlement (`com.apple.developer.devicecheck.appattest-environment`)

## Installation

Add the SDK to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/Adyen/adyen-issuing-ios", from: "1.0.0")
]
```

Then add the products you need to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "CardSessions", package: "adyen-issuing-ios"),
        .product(name: "CardProvisioningSessions", package: "adyen-issuing-ios"),
        .product(name: "IssuingCommon", package: "adyen-issuing-ios"),
    ]
)
```

## Quick Start

### Token Provider

All sessions require a `TokenProviding` implementation that fetches short-lived session tokens from your backend:

```swift
import IssuingCommon

struct MyTokenProvider: TokenProviding {
    func retrieveToken(for paymentInstrumentIds: Set<String>) async throws -> SessionToken {
        let raw = try await myBackend.fetchToken(for: paymentInstrumentIds)
        return SessionToken(raw)
    }
}
```

### Card Reveal

```swift
import CardSessions
import IssuingCommon

let session = CardSession(
    parameters: .init(appCertificate: certificate, environment: .live),
    tokenProvider: myTokenProvider
)

let details = try await session.revealCardDetails(paymentInstrumentId: "PI123...")
// details.pan, details.cvc, details.expiryMonth, details.expiryYear
```

### Apple Wallet Provisioning

```swift
import CardProvisioningSessions
import IssuingCommon

let session = try ProvisioningSession(
    parameters: .init(
        appCertificate: certificate,
        paymentInstrumentIds: ["PI123..."],
        keychainAccessGroup: "TEAM_ID.group.com.example.app",
        environment: .live
    ),
    tokenProvider: myTokenProvider
)

try await session.configure()

let state = await session.provisioningState(for: "PI123...")

switch state {
case .canProvision:
    // Show "Add to Apple Wallet" button
    let result = try await session.provision(paymentInstrumentId: "PI123...", viewController: self)
case .provisioned:
    // Card is already in Apple Wallet
    break
case .cannotProvision(let reason):
    // Handle reason (.notConfigured, .cannotAddCard, etc.)
    break
}
```

## Documentation

Full API reference and integration guides are available at:

**[adyen.github.io/adyen-issuing-ios](https://adyen.github.io/adyen-issuing-ios/)**

## Support

If you have a feature request, or spotted a bug or a technical problem, [create an issue here](https://github.com/Adyen/adyen-issuing-ios/issues).

For other questions, contact our [support team](https://www.adyen.help/).

## License

This SDK is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
