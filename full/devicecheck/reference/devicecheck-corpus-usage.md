# Untouched application usage contract

The original files remain untouched in the pinned corpus. This distilled usage
ledger identifies the surface the portable framework must typecheck.

## Signal

Signal stores a `DCAppAttestService`, checks `isSupported`, and uses the native
async forms of `generateKey()`, `attestKey(_:clientDataHash:)`, and
`generateAssertion(_:clientDataHash:)`. It catches `DCError` and switches on
`error.code`.

## Firefox

Firefox supplies `DCAppAttestService.shared` as the default implementation of
its App Attest protocol.

## Telegram

Telegram imports `DeviceCheck`; at the pinned revision this file does not use a
more specific public symbol.

No corpus source may be patched to accommodate the portable framework.
