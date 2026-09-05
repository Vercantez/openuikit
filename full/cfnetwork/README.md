# CFNetwork

Linux starting implementation of Apple's public `CFNetwork`
overlay, reconstructed from the sealed Xcode 26.1 iPhoneOS symbol graph. This
directory is not wired into the shared guest package; that integration is a
later central-review step.

## What is real

- `CFHTTPMessage` construction, case-insensitive header maps, body, HTTP/1.1
  serialization, incremental `AppendBytes` parsing (RFC 7230, including obs-fold
  and LF-or-CRLF terminators), and byte-exact serialize/parse/serialize round
  trips of unmodified messages.
- Basic authentication (RFC 7617) and Digest authentication (RFC 7616) for
  `MD5`, `MD5-sess`, `SHA-256`, and `SHA-256-sess`, including challenge parsing,
  `qop=auth` / `auth-int`, and the documented HTTP authentication stream error
  codes.
- `CFNetworkErrors` with every `kCFURLError*` / `kCFHost*` / `kCFSOCKS*` raw
  value from the seed, plus `kCFErrorDomainCFNetwork`.
- `CFHost` name and address objects, `getaddrinfo` resolution, reverse
  `getnameinfo`, and the three `CFHostInfoType` kinds (reachability stays
  unresolved).
- Local `CFNetService` objects plus DNS TXT dictionary round-trip.
- `CFNetworkCopySystemProxySettings` returns an empty dictionary;
  `CFNetworkCopyProxiesForURL` returns a single `kCFProxyTypeNone` (DIRECT)
  entry.
- UNIX `LIST` parsing in `CFFTPCreateParsedResourceListing`.
- Public HTTP versions (`kCFHTTPVersion*`), proxy keys, and
  `kCFStreamProperty*` socket-stream property constants.

The seed does not declare `CFURLRequest` / `CFURLResponse` overlay types.
Foundation `URLSession` / `HTTPCookie` remain the URL-loading implementation;
this module does not edit them.

## Fail-closed

- PAC JavaScript and PAC URL execution return `kCFErrorPACFileError` and never
  invent a proxy list.
- Bonjour register, resolve, browse, and TXT monitor return
  `kCFStreamErrorDomainNetServices` / `kCFNetServicesErrorUnknown`.
- `CFHost` reachability does not fabricate SystemConfiguration flags.
- NTLM, Kerberos, Negotiate, Negotiate2, and X-MobileMe authentication return
  `kCFStreamErrorHTTPAuthenticationTypeUnsupported`.
- `CFReadStreamCreateForHTTPRequest` and the FTP / socket-pair stream factories
  return inert CoreFoundation streams; they do not open a network connection or
  a TLS session (deprecated HTTP stream API).
- Interactive Network Diagnostics returns `kCFNetDiagnosticErr`.
- Cellular, expensive-path, and SSL stream properties exist only as keys.

## Deferred

None. All 472 precise identifiers are nondeferred (`implemented`). SHA-512-256
Digest, live Bonjour, PAC evaluation, and TLS session setup remain honest
fail-closed boundaries rather than invented success.

`tests/agent/CFNetworkRuntime.swift` runs the focused `test*` functions and prints
`CFNETWORK_AGENT_RUNTIME_OK`. Those same functions live in
`tests/agent/*Tests.swift` so every `implemented` coverage row can cite
`test:full/cfnetwork/tests/agent/<File>Tests.swift#testName`. Run
`bash tests/acceptance/test_host.sh` from this directory; keep generated products
out of the tree.

## Depth pass 2026-09

Depth pass over the existing seed (472 IDs). Starting coverage (seed before this
depth work) was **238 implemented / 234 declared**. The first depth commit labeled
all 472 rows `implemented` but cited `tests/agent/CFNetworkRuntime.swift`, which
the merge checker refused.

This repair keeps that overlay behavior and splits the runtime into 61 focused
top-level `func test*()` helpers. Every `implemented` row now cites a real test
of the form `test:full/cfnetwork/tests/agent/<File>Tests.swift#testName`. Enum
cases, option-set members, and C `k…` / `err…` constants share table-driven
value tests; function/type rows each cite the family test that calls that
identifier.

Public surface now exercised:

- RFC 7230 `CFHTTPMessage` incremental parse, obs-fold, LF/CRLF terminators,
  case-insensitive header copy, body/status/URL/method/version, and byte-exact
  round trips.
- RFC 7617 Basic and RFC 7616 Digest (MD5 and SHA-256 families) with the
  documented authentication error codes.
- Every `CFNetworkErrors` raw value, `kCFHTTPVersion*`, and
  `kCFStreamProperty*` string constants.
- `CFHostCreateWithName` / `CFHostCreateWithAddress` plus `getaddrinfo`.
- Empty system proxy dictionary and DIRECT `CFNetworkCopyProxiesForURL`.
- Fail-closed Bonjour (`CFNetService` / browser / monitor) and deprecated
  `CFReadStreamCreateForHTTPRequest`.

Coverage after this pass: **472 implemented / 0 declared / 0 deferred**.

Top-5 `implemented` evidence distribution (of 472):

1. `CFNetworkErrorTests.swift#testCFNetworkErrorRawValues` — 86 rows (18.2%)
2. `CFNetServiceFlagTests.swift#testCFNetServiceBrowserFlagAlgebra` — 28 (5.9%)
3. `CFNetServiceFlagTests.swift#testCFNetServiceRegisterFlagAlgebra` — 25 (5.3%)
4. `CFNetworkConstantTests.swift#testCFProxyKeyConstants` — 21 (4.4%)
5. `CFNetworkConstantTests.swift#testCFStreamPropertySSLAndAccessConstants` — 17 (3.6%)

No non-exempt test is cited by more than 40% of the remaining implemented rows
(largest remaining family test: `testCFNetServiceBrowser` at 15/154 = 9.7%).

Gate markers from `bash full/cfnetwork/tests/acceptance/test_host.sh` (Linux
host, no docker):

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
CFNETWORK_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CFNetwork dylib=libCFNetwork.dylib
```

Unresolved Apple-oracle questions remain in `oracle-questions.tsv` (PAC error
userInfo, NTLM/Kerberos/Negotiate wire bytes, reachability flag blobs, Bonjour
error codes, SOCKS subdomain packing, Mach/WinSock domain integers, interactive
diagnostics, deprecated HTTP-stream NULL vs inert, and SSL property payloads).
