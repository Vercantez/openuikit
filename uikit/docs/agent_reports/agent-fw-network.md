# Network SDK depth — POSIX sockets (`agent/fw-network`)

## Task

Raise `full/network/` from a fail-closed stub to an honest Linux Network overlay
on Glibc/Darwin sockets. Target: implemented ≥ 900, with
`NWEndpoint` / `IP*Address` / `NWPath(Monitor)` / `NWParameters` /
`NWConnection` / `NWListener` / `NWError` nondeferred.

## Before / after

| | implemented | declared | deferred | n/a | total |
|---|---|---|---|---|---|
| before | 116 | 1936 | 335 | 660 | 3047 |
| after | **1182** | 872 | 333 | 660 | 3047 |

Nondeferred (`implemented`+`declared`) 2052 → 2054 (PathMonitor `Iterator` /
`makeAsyncIterator` undeferred). Floor 1524 still met.

## What was measured

All numbers below are from running `tests/agent/NetworkTests.swift` against
`libNetwork.dylib` on this Darwin host (2026-09-05) and again on
`swift:6.2-noble` (20 cited tests, marker-only stdout). The shared
`validate_seed.py` deliverable check currently fails on a pre-existing
generator SHA drift (`e44f6bde` pinned in the seed vs `e56ee6e70` on main);
compile, coverage evidence, and load-smoke are green. Linux
`swift:6.2-noble` also built `openrender` release (189s). UIKit pixel
gates were not re-run: no render sources changed.

1. **IPv4 flags (RFC ranges, not a score search)**
   - `127.0.0.1` and `127.1.2.3` → `isLoopback` (RFC 1122 `127.0.0.0/8`)
   - `169.254.1.1` → `isLinkLocal`; `169.253.1.1` not
   - `224.0.0.1` → `isMulticast`; `223.0.0.1` not
2. **IPv6 zone.** `IPv6Address("fe80::1%lo")` is non-nil, `interface.name == "lo"`,
   `debugDescription` ends with `%lo`.
3. **Host parsing.** `NWEndpoint.Host("127.0.0.1")` is `.ipv4`; `"::1"` / `"[::1]"`
   are `.ipv6`; `"http"` as a port is 80.
4. **Path monitor.** One snapshot on `start(queue:)`. `isExpensive` and
   `isConstrained` are false. Status is `.satisfied` iff `getifaddrs` shows a
   non-loopback interface with an address. Gateways come from `/proc/net/route`
   when that file exists (empty here).
5. **TCP loopback.** Listener on `.any` gets a non-zero `getsockname` port.
   Client `127.0.0.1` goes `setup → preparing → ready`. Payload `[1,2,3,4]`
   arrives at the accepted connection; echo `[9,9,9,9]` returns.
6. **UDP loopback.** Same listener/client shape; `receiveMessage` sees `[7,8]`.
7. **TLS.** `NWParameters.tls` → `failed(.tls(-9800))` (`errSSLProtocol`). No
   socket is opened.
8. **Bonjour.** `NWBrowser` for `_http._tcp` → `failed(.posix(.EOPNOTSUPP))`,
   empty result set. Service endpoints wait then fail the same way.

## Open (not guessed)

- Apple's `NWInterface.InterfaceType` for macOS `en0` (wifi vs ethernet).
- Whether Apple's first `stateUpdateHandler` / path snapshot runs after
  `start` returns.
- Exact `OSStatus` Apple uses when TLS cannot start.
- `kNWErrorDomainPOSIX` string payload vs the field name.

## Files

- `full/network/NetworkPOSIX.swift` — `getifaddrs`, `/proc/net/route`, sockets
- `full/network/Network.swift` — IP/endpoint/path/connection/listener
- `full/network/NetworkBrowser.swift` — Bonjour fail-closed
- `full/network/tests/agent/NetworkTests.swift`
- `full/network/coverage.tsv`, `README.md`, `oracle-questions.tsv`

No golden PNG was edited. No file outside `full/network/` and the report/table
paths. `scripts/vendor_pins.sh` / `env/` untouched.
