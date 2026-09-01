# Cursor framework fan-out pilot: DeviceCheck

Starting platform commit: `646a9285a91b12065b5d1c588ec1ae450538e2e8`

This pilot measures whether a cloud agent can turn a committed SDK contract and
existing platform patterns into a useful first-party framework tranche without
an Apple runtime oracle.

DeviceCheck is deliberately small but nontrivial: it combines imported
Objective-C classes, a bridged NSError family, completion-handler APIs, native
Swift async overloads, singleton identity, a security boundary, and real usage
in untouched open-source applications.

Use these in-repository implementations as patterns, not files to edit:

- `full/adservices/AdServices.swift`: typed NSError and fail-closed behavior
- `full/localauthentication/LocalAuthentication.swift`: callback/async parity
- `full/authenticationservices/AuthenticationServices.swift`: honest host
  boundary policy
- `full/corelocation/tests/test_corelocation_host.sh`: manifest, corpus, and
  boundary auditing style

The portable behavior is intentionally fail-closed. A Linux host cannot issue
Apple-authenticated device tokens or App Attest cryptographic material. A
fabricated success would be a security bug.

Success means a reviewable, committed `full/devicecheck/` tranche whose source
surface compiles and whose runtime acceptance program cold-runs on Linux. It
does not mean production package integration or Apple runtime parity.
