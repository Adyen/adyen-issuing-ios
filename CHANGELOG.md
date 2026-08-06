# Changelog

All notable changes to the Adyen Issuing iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0]

### Added

#### CardSessions
- Card detail reveal (PAN, CVC, expiry month, expiry year) via end-to-end encryption.
- PIN reveal for cardholders.
- PIN change for cardholders.
- `CardSessionError` with structured error codes and `ErrorContext` for support correlation.

#### CardProvisioningSessions
- Session-based Apple Wallet provisioning with `ProvisioningSession`.
- Provisioning state checking per payment instrument (phone, watch, or both).
- `WalletExtensionHandler` base class for non-UI Issuer Provisioning Extensions.
- `WalletExtensionUIHandler` base class for UI-based extension authentication.
- `CardProvisioningError` with structured error codes and `ErrorContext` for support correlation.

#### IssuingCommon
- `TokenProviding` protocol for session token retrieval.
- `SessionToken` opaque wrapper with redacted string representations.
- `SessionEnvironment` for environment configuration (`.live`, `.test`).
- `ErrorContext` for sanitized error diagnostics (`requestId`, `traceParent`).

#### Legacy Modules
- `CardProvisioning` for delegate-based in-app provisioning.
- `CardProvisioningExtension` for non-UI Issuer Extension callbacks.

> New integrations should use `CardProvisioningSessions` instead of the legacy modules.
