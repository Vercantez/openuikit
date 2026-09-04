# Compression

Linux starting point for Apple's public `Compression` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success.

Host-compiled sources import **Foundation only**. The existing C Brotli host
(`OpenCompressionHost.c`, `OpenCompressionBridge.c`, `COpenCompression`) is
kept for the guest/C oracle; the host gate compiles the Swift port below.

## What is real

Portable Swift implementations exercised by `tests/agent/CompressionTests.swift`:

- `compression_algorithm` / `compression_status` / `compression_stream_flags` /
  `compression_stream_operation` raw values from Apple `compression.h` and
  pinned `dotnet/macios` `Compression/Enums.cs`
- `compression_encode_buffer` / `compression_decode_buffer` for
  `COMPRESSION_ZLIB` (RFC 1950 stored deflate), `COMPRESSION_LZ4` (LZ4 frame),
  `COMPRESSION_LZ4_RAW` (LZ4 block), and `COMPRESSION_BROTLI`
- Decode of `tests/compression-brotli-apple-2026-09-01.txt` (the IceCubes
  RevenueCat Brotli transcript) through `compression_decode_buffer`
- Swift overlay `Algorithm`, `FilterOperation`, `FilterError`, `InputFilter`,
  and `OutputFilter`, including zlib filter round-trips and fail-closed
  `bufferCapacity <= 0` / double-`finalize`
- `compression_stream_init` / `process` / `destroy` for a complete source
  buffer with `COMPRESSION_STREAM_FINALIZE`

`libCompression.dylib` compiles with `-warnings-as-errors`.

`COMPRESSION_LZFSE`, `COMPRESSION_LZMA`, and `COMPRESSION_LZBITMAP` encode and
decode return `0` / `FilterError.invalidData` (fail-closed; no those codecs on
this Linux lane). Scratch-size queries return `0`; encode/decode ignore the
scratch pointer and allocate internally.

## Fail-closed boundaries

- LZFSE, LZMA, and LZBITMAP have no Linux provider here.
- `compression_stream_process` buffers input until `FINALIZE` and then
  one-shot transforms. It is not claimed to match Apple incremental output.
- zlib encodes stored blocks, not Apple's level-5 deflate bytes.
- Brotli encoding uses libbrotli quality 5 when the shared library is present
  (same as the existing C host); otherwise uncompressed Brotli metablocks.
  Apple encode byte identity is not claimed except that the pinned transcript
  decodes.

## Deferred

See `oracle-questions.tsv`. Incremental stream process, Apple scratch sizes,
Apple zlib/Brotli encoder bytes, and LZFSE/LZMA/LZBITMAP remain deferred until
an Apple-runtime oracle or a real Linux codec exists.

## Tests

- `tests/agent/CompressionLoadSmoke.swift` — canonical schema-v2 marker
- `tests/agent/CompressionTests.swift` — focused `test*` probes (no stdout)
- `tests/agent/CompressionDependencyIdentity.swift` — Foundation `Data` through public APIs
- `tests/agent/CompressionRuntime.swift` — optional schema-v1-style probe (not host-compiled)
- `tests/CompressionGuestRuntime.swift` — existing Swift overlay / Apple Brotli guest probe
- `tests/OpenCompressionHostTests.c` — existing C Brotli host oracle

