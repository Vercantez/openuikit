# DeviceCheck pilot ownership

This directory is an isolated framework-porting task for a Cursor Cloud Agent.

## Scope

- You own only `full/devicecheck/**`.
- Do not edit shared manifests, framework counts, `build_core_guest_package.sh`,
  Xcode-plan files, or any other framework directory.
- Do not modify the committed files under `reference/` or weaken the committed
  source/runtime acceptance programs under `tests/`.
- Do not change any third-party application source.

## Evidence

- Treat `reference/DeviceCheck.symbols.json` as the authoritative Xcode 26.1
  public Swift surface for this pilot.
- Treat `reference/devicecheck-public-boundary.tsv` as the public dynamic
  boundary. Private TBD classes are explicit exclusions.
- Treat `reference/apple-sdk-inputs.sha256` as provenance. Raw Apple SDK headers
  are deliberately not committed.
- Treat `reference/devicecheck-corpus-2026-09-01.tsv` and
  `reference/devicecheck-corpus-usage.md` as untouched-app compatibility
  requirements.
- The cloud runner has no Apple runtime oracle. Never claim Apple behavioral
  parity for a value that was not established by committed evidence.

## Required behavior

- Reconstruct the complete public surface represented in the symbol graph.
- Preserve stable identity for `DCDevice.current` and
  `DCAppAttestService.shared`.
- Linux has no Apple DeviceCheck/App Attest or Secure Enclave attestation
  service. `isSupported` must be `false`.
- Every callback operation must complete exactly once with a nil result and a
  typed `DCError(.featureUnsupported)`.
- Every native async overload must throw the same typed error.
- Never fabricate a successful device token, key identifier, attestation, or
  assertion.
- Keep callback and async behavior consistent.

## Deliverables and proof

- `DeviceCheck.swift`
- `devicecheck_guest_sources.txt`
- `README.md` with supported behavior and honest remaining limitations
- `tests/test_devicecheck_host.sh`
- Any small test helper files needed under `tests/`
- A Linux `swiftc` source-surface typecheck and cold runtime test using the
  committed acceptance programs
- Boundary/provenance tests that reject accidental private TBD exports

Run every available test, record exact commands/results in the final response,
and commit the completed directory. Do not integrate it into the shared package;
that is a separate central review step.
