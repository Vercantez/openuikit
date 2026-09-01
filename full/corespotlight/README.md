# Portable CoreSpotlight

This directory implements Apple's `CoreSpotlight` source identity as a real
framework product for the Linux-hosted ARM64 Mach-O platform. It provides named
volatile indexes, owned item and attribute snapshots, callback and async CRUD,
domain deletion, expiration filtering, deterministic term queries, batch client
state, and AppIntents entity mutation hooks. The public content-type initializer
uses the platform's independent `UniformTypeIdentifiers` module.

The implementation does not claim Apple's private search daemon or durable
system index. A host can inspect/query the process-local index through the
attested SPI without changing application source.

Run the shared native-shape and runtime gate with:

```sh
bash full/backgroundtasks/tests/test_background_spotlight_host.sh
```
