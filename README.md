# Adyen Issuing SDK for iOS

[![Platform](https://img.shields.io/badge/platform-iOS%2014%2B-blue)](https://developer.apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

The Adyen Issuing SDK enables iOS apps to integrate with Adyen's card issuing platform. It provides end-to-end encrypted card detail retrieval, PIN management, and Apple Wallet provisioning — all without sensitive data ever touching your server.

## Features

- **Card reveal** — securely display PAN, CVC, and expiry date in your app
- **PIN reveal & change** — let cardholders view or update their PIN
- **Apple Wallet provisioning** — add cards to Apple Pay from within your app
- **Wallet Extensions** — support in-app provisioning and Issuer Extensions for the Apple Wallet app

## Modules

| Library | Description |
|---|---|
| `CardSessions` | Card reveal (PAN, CVC, expiry), PIN reveal, and PIN change |
| `CardProvisioningSessions` | Apple Wallet provisioning sessions and Wallet Extension handlers |
| `CardProvisioning` | In-app provisioning service and delegate protocol |
| `CardProvisioningExtension` | Non-UI Issuer Extension for provisioning callbacks |
| `IssuingCommon` | Shared types (`TokenProviding`, `IssuingEnvironment`, `SessionToken`) |

## Requirements

- iOS 14.0+
- Swift 5.9+
- Xcode 16.0+
- An [Adyen Issuing](https://www.adyen.com/issuing) integration on your backend
- An app certificate issued by Adyen (required for `CardSessions` and `CardProvisioningSessions`)

## Installation

Add the SDK to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/Adyen/adyen-issuing-ios", from: "1.0.0")
]
```

Then import the libraries you need:

```swift
import CardSessions              // Card reveal & PIN
import CardProvisioningSessions  // Apple Wallet provisioning
```

## Getting Started

### Card Reveal

```swift
let session = CardSession(
    parameters: .init(appCertificate: certificate, environment: .live),
    tokenProvider: myTokenProvider
)

let details = try await session.revealCardDetails(paymentInstrumentId: "PI123...")
// details.pan, details.cvc, details.expiryMonth, details.expiryYear
```

### Apple Wallet Provisioning

```swift
let session = ProvisioningSession(
    parameters: .init(
        appCertificate: certificate,
        environment: .live,
        keychainAccessGroup: "group.com.example.app"
    ),
    paymentInstrumentIds: ["PI123..."],
    tokenProvider: myTokenProvider
)

try await session.configure()
let state = try await session.cardState(for: "PI123...")
```

### Token Provider

All sessions require a `TokenProviding` implementation (from `IssuingCommon`) that fetches a short-lived session token from your backend:

```swift
import IssuingCommon

struct MyTokenProvider: TokenProviding {
    func retrieveToken(for paymentInstrumentIds: Set<String>) async throws -> SessionToken {
        let raw = try await myBackend.fetchToken(for: paymentInstrumentIds)
        return SessionToken(raw)
    }
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
