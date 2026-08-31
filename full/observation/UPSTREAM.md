# Observation source provenance

The Swift sources in `Sources/Observation` are byte-for-byte copies from the
official `swiftlang/swift` repository, tag `swift-6.2.4-RELEASE`, commit
`ee343b46aef81c3ac7c5d7960cb35a41a88c5a9b`, under
`stdlib/public/Observation/Sources/Observation`.

They retain the upstream Apache License 2.0 with Runtime Library Exception
headers. `ObservationRuntimeBridge.c` is a platform-owned replacement for the
upstream C++ helpers. It deliberately uses only public Darwin lock and pthread
ABIs already implemented by the platform's `libSystem` compatibility layer.

