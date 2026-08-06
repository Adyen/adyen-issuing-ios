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
IssuingCommon               — Shared types (TokenProviding, SessionToken, SessionEnvironment)
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
- Always import `IssuingCommon` when using `TokenProviding`, `SessionToken`, or `SessionEnvironment`.

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

3. **App Attest entitlement** — required for all session-based operations. Add the `com.apple.developer.devicecheck.appattest-environment` entitlement to your app:
   - `"development"` — use with `SessionEnvironment.test`. Card operations (reveal, PIN) work fully. Provisioning flow is limited.
   - `"production"` — use with `SessionEnvironment.live`. Full provisioning flow requires an App Store or TestFlight build. TestFlight builds automatically set the App Attest environment to `"production"`.

4. **Entitlements** (provisioning only):
   - `com.apple.developer.payment-pass-provisioning`
   - Keychain access group shared between the app and the Wallet Extension

## Environment

The SDK environment must match your App Attest entitlement value:

```swift
import IssuingCommon

// App Attest entitlement = "production" (App Store / TestFlight builds)
let env: SessionEnvironment = .live

// App Attest entitlement = "development" (local builds)
let env: SessionEnvironment = .test
```

> **Note:** The full Apple Wallet provisioning flow is only available with `.live` environment and an App Store or TestFlight build.

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
} catch let error as CardSessionError {
    switch error.code {
    case .invalidSessionToken:
        // Token expired or invalid — re-authenticate
    case .publicKeyExpired:
        // Certificate issue — contact Adyen
    case .revealFailed:
        // Reveal operation failed
    default:
        break
    }

    // Use underlyingError for support correlation
    if let context = error.underlyingError {
        print("Request ID: \(context.requestId ?? "N/A")")
        print("Trace: \(context.traceParent ?? "N/A")")
        print("HTTP status: \(context.httpErrorCode.map(String.init) ?? "N/A")")
    }
}
```

The `underlyingError` property returns an `ErrorContext?` (from `IssuingCommon`) containing backend trace identifiers (`requestId`, `traceParent`) and the HTTP status code (`httpErrorCode`). Internal SDK error details are never exposed.

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
        keychainAccessGroup: "TEAM_ID.group.com.example.app",
        environment: .live,
        shouldRefreshCachedData: true,   // default: true — fetches fresh activation data
        isWatchActivated: nil            // default: nil — auto-detects watch pairing
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
} catch let error as CardProvisioningError {
    switch error.code {
    case .noPaymentInstrumentsProvided:
        // Empty paymentInstrumentIds
    case .couldNotEstablishSession:
        // Network or auth failure
    case .activationDataUnavailable:
        // Could not fetch activation data
    case .provisioningCancelled:
        // User dismissed the Apple Pay sheet
    default:
        break
    }

    // Use underlyingError for support correlation
    if let context = error.underlyingError {
        print("Request ID: \(context.requestId ?? "N/A")")
        print("HTTP status: \(context.httpErrorCode.map(String.init) ?? "N/A")")
    }
}
```

The `underlyingError` property returns an `ErrorContext?` (from `IssuingCommon`) containing backend trace identifiers and the HTTP status code. Internal SDK error details are never exposed.

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

    override func environment() -> SessionEnvironment {
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

Subclass `WalletExtensionUIHandler` in your Issuer Provisioning Extension UI target. Build your authentication UI inside the initializer and call `completeAuthorization(result:)` when the user finishes.

```swift
import CardProvisioningSessions
import UIKit

class WalletUIExtensionHandler: WalletExtensionUIHandler {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        let authViewController = YourAuthViewController { [weak self] success in
            self?.completeAuthorization(result: success ? .authorized : .canceled)
        }

        addChild(authViewController)
        view.addSubview(authViewController.view)
        authViewController.view.frame = view.bounds
        authViewController.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        children.first?.view.frame = view.bounds
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
```

SwiftUI is also supported via `UIHostingController`.

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
| `ProvisioningState` | `CardProvisioningSessions` | State enum (@MainActor): canProvision, provisioned, cannotProvision |
| `CardActivationState` | `CardProvisioningSessions` | Result of provisioning (@MainActor): activated, requiresActivation, etc. |
| `CardProvisioningError` | `CardProvisioningSessions` | Error type for provisioning operations |
| `CardProvisioningSessions.Configuration` | `CardProvisioningSessions` | Config: appCertificate, paymentInstrumentIds, keychainAccessGroup, environment, shouldRefreshCachedData, isWatchActivated |
| `WalletExtensionHandler` | `CardProvisioningSessions` | Base class for non-UI Wallet Extension |
| `WalletExtensionUIHandler` | `CardProvisioningSessions` | Base class for UI Wallet Extension (auth) |
| `AuthorizationResult` | `CardProvisioningSessions` | Auth outcome (@MainActor): .authorized, .canceled |
| `TokenProviding` | `IssuingCommon` | Protocol for session token retrieval |
| `SessionToken` | `IssuingCommon` | Opaque token wrapper (redacted in logs) |
| `SessionEnvironment` | `IssuingCommon` | Environment (struct, RawRepresentable): .live, .test |
| `ErrorContext` | `IssuingCommon` | Sanitized error diagnostics (requestId, traceParent, httpErrorCode) for support correlation |
| `ProvisioningService` | `CardProvisioning` | Legacy in-app provisioning (delegate-based) |
| `ProvisioningServiceDelegate` | `CardProvisioning` | Delegate for legacy provisioning callbacks (@MainActor) |
| `ProvisioningServiceError` | `CardProvisioning` | Error type for legacy provisioning |
| `ExtensionProvisioningService` | `CardProvisioningExtension` | Legacy non-UI extension service |
| `ExtensionProvisioningServiceDelegate` | `CardProvisioningExtension` | Delegate for legacy extension callbacks |
