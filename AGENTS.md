# Adyen Issuing iOS SDK — Agent Integration Guide

This file helps AI coding assistants integrate the Adyen Issuing SDK into client iOS apps.
Read this file in full before generating any integration code.

## SDK Overview

The Adyen Issuing SDK provides:
- In-app card detail reveal (PAN, CVC, expiry)
- PIN reveal and PIN change
- Apple Wallet provisioning (in-app and via Wallet Extensions)

All operations are session-based. Each session requires an app certificate (issued by Adyen, `.der` format) and a token provider that fetches short-lived session tokens from the client's backend.

## Module Map

```
IssuingCommon               — Shared types (TokenProviding, SessionToken, IssuingEnvironment)
CardSessions                — Card reveal, PIN reveal, PIN change (depends on IssuingCommon)
CardProvisioningSessions    — Apple Wallet provisioning sessions + Wallet Extension handlers (depends on IssuingCommon)
CardProvisioning            — Legacy in-app provisioning service (lower-level, delegate-based)
CardProvisioningExtension   — Legacy non-UI Issuer Extension service
```

### Which modules to import

| Use case | Import |
|---|---|
| Card reveal / PIN | `CardSessions`, `IssuingCommon` |
| Apple Wallet provisioning (recommended) | `CardProvisioningSessions`, `IssuingCommon` |
| Apple Wallet provisioning (legacy) | `CardProvisioning` |
| Wallet Extension (non-UI) | `CardProvisioningSessions`, `IssuingCommon` |
| Wallet Extension (UI / auth) | `CardProvisioningSessions`, `IssuingCommon` |

### Rules

- **Never** import `IssuingCore` — it is an internal module and not part of the public API.
- **Never** import `Card` — it is an internal dependency of `CardSessions`.
- Always import `IssuingCommon` when using `TokenProviding`, `SessionToken`, or `IssuingEnvironment`.

## Prerequisites

1. **App certificate** — a `.der` certificate issued by Adyen. Load it as `Data`:
   ```swift
   guard let certURL = Bundle.main.url(forResource: "adyen-certificate", withExtension: "der"),
         let certificate = try? Data(contentsOf: certURL) else {
       fatalError("Missing Adyen app certificate")
   }
   ```

2. **Token provider** — implements `TokenProviding` (from `IssuingCommon`). Must call the client's backend to obtain a short-lived session token:
   ```swift
   import IssuingCommon

   struct MyTokenProvider: TokenProviding {
       func retrieveToken(for paymentInstrumentIds: Set<String>) async throws -> SessionToken {
           let raw = try await myBackend.fetchToken(for: paymentInstrumentIds)
           return SessionToken(raw)
       }
   }
   ```

3. **Entitlements** (provisioning only):
   - `com.apple.developer.payment-pass-provisioning`
   - Keychain access group shared between the app and the Wallet Extension

## Environment

```swift
import IssuingCommon

// Production
let env: IssuingEnvironment = .live

// Testing (provisioning flow is limited in test)
let env: IssuingEnvironment = .test
```

## Card Reveal & PIN

### Setup

```swift
import CardSessions
import IssuingCommon

let session = CardSession(
    parameters: CardSessions.Configuration(
        appCertificate: certificate,
        environment: .live
    ),
    tokenProvider: myTokenProvider
)
```

### Reveal card details

```swift
let details = try await session.revealCardDetails(paymentInstrumentId: "PI123...")
// details.pan       — full PAN (String)
// details.cvc       — CVC (String)
// details.expiryMonth — e.g. "03" (String)
// details.expiryYear  — e.g. "2027" (String)
```

### Reveal PIN

```swift
let pin = try await session.revealPin(paymentInstrumentId: "PI123...")
```

### Change PIN

```swift
try await session.changePin(paymentInstrumentId: "PI123...", newPin: "1234")
```

### Error handling

All `CardSession` methods throw `CardSessionError`. Match on error codes:

```swift
do {
    let details = try await session.revealCardDetails(paymentInstrumentId: id)
} catch CardSessionError.invalidSessionToken {
    // Token expired or invalid — re-authenticate
} catch CardSessionError.publicKeyExpired {
    // Certificate issue — contact Adyen
} catch CardSessionError.revealFailed {
    // Reveal operation failed
} catch {
    // Other error
}
```

Error codes: `invalidSessionToken`, `publicKeyExpired`, `couldNotEstablishSession`, `revealFailed`, `pinRevealFailed`, `pinChangeFailed`, `invalidPin`.

## Apple Wallet Provisioning (Recommended)

Use `CardProvisioningSessions` for the session-based provisioning flow.

### Setup

```swift
import CardProvisioningSessions
import IssuingCommon

let session = try ProvisioningSession(
    parameters: CardProvisioningSessions.Configuration(
        appCertificate: certificate,
        paymentInstrumentIds: ["PI123...", "PI456..."],
        keychainAccessGroup: "group.com.example.app",
        environment: .live
    ),
    tokenProvider: myTokenProvider
)
```

### Configure (must call before any other method)

```swift
try await session.configure()
```

### Check provisioning state

```swift
let state = await session.provisioningState(for: "PI123...")

switch state {
case .canProvision(let devices):
    // Show "Add to Apple Wallet" button
    // devices: .phone, .phoneAndWatch, .provisionedOnWatchCanProvisionOnPhone,
    //          .provisionedOnPhoneCanProvisionOnWatch(passURL)
case .provisioned(let devices):
    // Card is already in Apple Wallet
    // devices: .phone(passURL), .phoneAndWatch(passURL)
case .cannotProvision(let reason):
    // Cannot provision — check reason
    // reason: .notConfigured, .provisioningError(_), .missingPassURL,
    //         .cannotAddCard, .unexpectedCardState
}
```

### Provision

```swift
// Must be called on @MainActor with a presenting view controller
let result = try await session.provision(
    paymentInstrumentId: "PI123...",
    viewController: self
)

switch result {
case .activated:        // Card is active and ready
case .requiresActivation: // User needs to verify (SMS, email, etc.)
case .activating:       // Activation in progress
case .suspended:        // Card is suspended
case .deactivated:      // Card is deactivated
case .unknown:          // Unknown state
}
```

### Error handling

```swift
do {
    try await session.configure()
} catch CardProvisioningError.noPaymentInstrumentsProvided {
    // Empty paymentInstrumentIds
} catch CardProvisioningError.couldNotEstablishSession {
    // Network or auth failure
} catch CardProvisioningError.activationDataUnavailable {
    // Could not fetch activation data
} catch CardProvisioningError.provisioningCancelled {
    // User dismissed the Apple Pay sheet
}
```

Error codes: `noPaymentInstrumentsProvided`, `noKeychainGroupIdProvided`, `couldNotEstablishSession`, `activationDataUnavailable`, `provisioningAlreadyInProgress`, `provisioningCancelled`, `provisioningFailed`.

## Wallet Extension (Non-UI)

Subclass `WalletExtensionHandler` in your Issuer Provisioning Extension target.

```swift
import CardProvisioningSessions
import IssuingCommon
import CoreGraphics

class MyExtensionHandler: WalletExtensionHandler {

    override func keychainAccessGroup() -> String {
        "group.com.example.app"
    }

    override func environment() -> IssuingEnvironment {
        .live
    }

    override func shouldAuthenticateUser() -> Bool {
        true // or false
    }

    override func sessionToken(paymentInstrumentIds: [String]) async throws -> SessionToken {
        let raw = try await myBackend.fetchToken(for: Set(paymentInstrumentIds))
        return SessionToken(raw)
    }

    override func cardArt(paymentInstrumentId: String, brand: String) -> CGImage {
        // Return a CGImage for the card art
        UIImage(named: "card-\(brand)")!.cgImage!
    }
}
```

Set this class as the `NSExtensionPrincipalClass` in the extension's `Info.plist`.

## Wallet Extension (UI / Auth)

Subclass `WalletExtensionUIHandler` in your Issuer Provisioning Extension UI target.

```swift
import CardProvisioningSessions

class MyAuthHandler: WalletExtensionUIHandler {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Present your authentication UI (e.g. Face ID, PIN entry)
        authenticateUser { [weak self] success in
            self?.completeAuthorization(result: success ? .authorized : .canceled)
        }
    }
}
```

Set this class as the `NSExtensionPrincipalClass` in the UI extension's `Info.plist`.

## Constraints — Do NOT

- **Do not** log or persist `CardDetails.pan` or `CardDetails.cvc` — they are redacted in all string representations by design.
- **Do not** access `SessionToken.rawValue` — it is internal to the SDK (`@_spi`).
- **Do not** import `IssuingCore` or `Card` — they are internal modules.
- **Do not** pass raw token strings to the SDK — always wrap in `SessionToken(rawString)`.
- **Do not** call `provision()` or `provisioningState()` before `configure()` — it will return `.cannotProvision(.notConfigured)`.
- **Do not** start multiple provisioning flows for the same payment instrument simultaneously.
- **Do not** use `.test` environment for full provisioning flows — Apple Pay provisioning is limited in test.

## SPM Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Adyen/adyen-issuing-ios", from: "1.0.0")
]

// Target dependency examples:
.product(name: "CardSessions", package: "adyen-issuing-ios"),
.product(name: "CardProvisioningSessions", package: "adyen-issuing-ios"),
.product(name: "IssuingCommon", package: "adyen-issuing-ios"),
```

## Type Reference

| Type | Module | Purpose |
|---|---|---|
| `CardSession` | `CardSessions` | Card reveal, PIN reveal, PIN change |
| `CardDetails` | `CardSessions` | Returned by `revealCardDetails` (pan, cvc, expiryMonth, expiryYear) |
| `CardSessionError` | `CardSessions` | Error type for card session operations |
| `CardSessions.Configuration` | `CardSessions` | Config: appCertificate, environment |
| `ProvisioningSession` | `CardProvisioningSessions` | Apple Wallet provisioning session |
| `ProvisioningState` | `CardProvisioningSessions` | State enum: canProvision, provisioned, cannotProvision |
| `CardActivationState` | `CardProvisioningSessions` | Result of provisioning: activated, requiresActivation, etc. |
| `CardProvisioningError` | `CardProvisioningSessions` | Error type for provisioning operations |
| `CardProvisioningSessions.Configuration` | `CardProvisioningSessions` | Config: appCertificate, paymentInstrumentIds, keychainAccessGroup, environment |
| `WalletExtensionHandler` | `CardProvisioningSessions` | Base class for non-UI Wallet Extension |
| `WalletExtensionUIHandler` | `CardProvisioningSessions` | Base class for UI Wallet Extension (auth) |
| `AuthorizationResult` | `CardProvisioningSessions` | Auth outcome: .authorized, .canceled |
| `TokenProviding` | `IssuingCommon` | Protocol for session token retrieval |
| `SessionToken` | `IssuingCommon` | Opaque token wrapper (redacted in logs) |
| `IssuingEnvironment` | `IssuingCommon` | Environment: .live, .test |
| `ProvisioningService` | `CardProvisioning` | Legacy in-app provisioning (delegate-based) |
| `ProvisioningServiceDelegate` | `CardProvisioning` | Delegate for legacy provisioning callbacks |
| `ProvisioningServiceError` | `CardProvisioning` | Error type for legacy provisioning |
| `ExtensionProvisioningService` | `CardProvisioningExtension` | Legacy non-UI extension service |
| `ExtensionProvisioningServiceDelegate` | `CardProvisioningExtension` | Delegate for legacy extension callbacks |
