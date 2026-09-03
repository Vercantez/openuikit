# CFNetwork

Linux starting implementation of Apple's public `CFNetwork` overlay, reconstructed
from the sealed Xcode 26.1 iPhoneOS symbol graph. This directory is not wired
into the shared guest package; that integration is a later central-review step.

## What is real

- `CFHTTPMessage` construction, header maps, body, HTTP/1.x serialization, and
  `AppendBytes` parsing.
- Basic authentication (`Authorization: Basic`) from a `WWW-Authenticate`
  challenge. Digest, NTLM, Kerberos, Negotiate, and X-MobileMe remain
  fail-closed.
- `CFHost` name objects and `getaddrinfo` address resolution for names such as
  `localhost`. Reverse lookup uses `getnameinfo` when an address is supplied.
- Local `CFNetService` objects plus DNS TXT dictionary round-trip.
- Environment-based proxy settings (`http_proxy` / `no_proxy`) for
  `CFNetworkCopySystemProxySettings` and `CFNetworkCopyProxiesForURL`.
- UNIX `LIST` parsing in `CFFTPCreateParsedResourceListing`.
- Public error enumerations, HTTP versions, proxy keys, and stream-property
  constants.

## Fail-closed

- PAC JavaScript and PAC URL execution return `kCFErrorPACFileError` and never
  invent a proxy list.
- Bonjour register, resolve, browse, and TXT monitor return
  `kCFStreamErrorDomainNetServices` / `kCFNetServicesErrorUnknown`.
- `CFHost` reachability does not fabricate SystemConfiguration flags.
- HTTP, FTP, and socket-pair streams are inert CoreFoundation streams; they do
  not open a network connection or a TLS session.
- Interactive Network Diagnostics returns `kCFNetDiagnosticErr`.
- Cellular, expensive-path, and SSL stream properties exist only as keys.

## Deferred

Cookie storage, URL cache objects, and private TBD symbols are outside the
public Swift overlay captured by this seed and are not declared here.

`tests/agent/CFNetworkRuntime.swift` exercises the implemented surface and prints
`CFNETWORK_AGENT_RUNTIME_OK`. Run `bash tests/acceptance/test_host.sh` from this
directory; keep generated products out of the tree.
