# Guest Foundation: URLSession family (APP LADDER networking row)

## What was measured

Darwin Apple Foundation on this Mac, macOS 26, 2026-09-06. Probes in
`/tmp/urlcomponents-oracle-probe.swift` and the Apple half of
`full/foundation/tests/FoundationURLComponentsOracle.swift`. Guest types
are declared in the existing 41-file facade (`URLLoading.swift`,
`URLSession.swift`); no new manifest line, so the five operator pins stay
put.

Native Mac check: `bash full/foundation/tests/test_foundation_oracles_host.sh`
— Apple transcript `cmp`s the carried golden, then the port module does too.

## URLComponents (83-row golden, empty diff)

Carried golden: `full/foundation/tests/foundation-urlcomponents-apple-2026-09-06.txt`
(83 rows, sha256 `bd97aa971993af1fef9636a2e2a1731cb7559ff107f4c144d813482923d81111`).

Rules read off Apple, not a score search:

- Query-item encode set = `urlQueryAllowed` minus `&` (0x26) and `=` (0x3D).
  Space → `%20`; `+` stays `+`.
- Store percent-encoded forms. `%2F` in path is kept in `percentEncodedPath`;
  decoded `path` has `/`.
- Empty query `?` → `query == ""`, `queryItems == []`. Nil query → nil items.
  `?a` → name `a`, value nil.
- IPv6 host includes brackets (`[::1]`). Zone id: peHost `[fe80::1%25en0]`,
  host `[fe80::1%en0]`.
- `encodingInvalidCharacters: false` rejects café in path; default/`true`
  percent-encodes.
- Authority + path without a leading `/` → `string`/`url` nil.
- IDNA: `host` is unicode; `percentEncodedHost` is percent-UTF-8 of unicode;
  `string`/`url` use punycode (`http://xn--fsq.com` → host `例.com`). RFC 3492
  encode+decode in `_Punycode` (`例`↔`fsq`, `café`↔`caf-dma`).

`URLRequest.setValue` keeps the original header-key casing. `addValue` joins
with a comma and **no space**.

## URLSessionTask / configuration / HTTPURLResponse

Measured on Apple URLSession, macOS 26:

- New tasks: `state = suspended` (rawValue 1), `priority = 0.5`,
  `defaultPriority = 0.5`, `low = 0.25`, `high = 0.75`.
- `httpMaximumConnectionsPerHost = 6`, `waitsForConnectivity = false`,
  `httpCookieAcceptPolicy` rawValue **2** (`onlyFromMainDocumentDomain`).
- `background(withIdentifier:)` creates and stores the identifier
  (`sessionSendsLaunchEvents = true`). Guest **use** fail-closes with
  `URLError.cannotLoadFromNetwork` and detail `"background URLSession is not available"`
  (no `nsurlsessiond`).
- `HTTPURLResponse.suggestedFilename`: `filename*` wins over `filename`;
  Content-Disposition present but no filename → `Unknown`; else last path
  component, then append the MIME ext if it is not already the last
  extension (`b.txt` + `text/html` → `b.txt.html`).
- `localizedString(forStatusCode:)`: 418/unlisted 4xx → `"client error"`;
  200 → `"no error"`; 301 → `"moved permanently"`; 308 → `"redirected"`.

HTTPS on the existing curl transport stays verified (system CA). The brief's
"https fails closed" is **not** the measured Darwin rule and is not modelled.
`URLSessionStreamTask.resume` fail-closes `unsupportedURL`.

Delegate callbacks run inline: guest `OperationQueue` has no `addOperation`.

## model-supply ABSENT (same 20-app census JSON)

`python3 full/ladder/model_supply.py ladder-census-2026-09-14.json …`

| | 2026-09-14 | this branch |
|---|---|---|
| guest files / types | 41 / 128 | 41 / **147** |
| GUEST-ORACLE uses | 5,728 (4.4 %) | **6,300 (4.8 %)** |
| GUEST-FOUNDATION | 37,513 (28.7 %) | **38,722 (29.6 %)** |
| ABSENT uses | 2,983 (2.3 %) | **1,202 (0.9 %)** |

URLSession-family names that left ABSENT (apps/uses from the 09-14 census):

| name | before | after |
|---|---|---|
| `URLComponents` | 18 / 572 ABSENT | GUEST-ORACLE |
| `URLQueryItem` | 17 / 615 ABSENT | GUEST-FOUNDATION |
| `URLSessionTask` | 12 / 175 ABSENT | GUEST-FOUNDATION |
| `URLSessionDataTask` | 11 / 65 ABSENT | GUEST-FOUNDATION |
| `URLSessionDownloadTask` | 7 / 58 ABSENT | GUEST-FOUNDATION |
| `URLSessionUploadTask` | 5 / 13 ABSENT | GUEST-FOUNDATION |
| `URLSessionDataDelegate` | 6 / 14 ABSENT | GUEST-FOUNDATION |
| `URLCredential` | 8 / 129 ABSENT | GUEST-FOUNDATION |
| `URLAuthenticationChallenge` | 8 / 92 ABSENT | GUEST-FOUNDATION |
| `URLProtectionSpace` | 4 / 35 ABSENT | GUEST-FOUNDATION |
| `NSURLComponents` | 7 / 13 ABSENT | GUEST-FOUNDATION (`typealias`) |

Still ABSENT (ObjC names, not declared): `NSURLSession` 5/10, `NSURLRequest` 4/6,
`NSHTTPURLResponse` 2/2, `NSURLConnection` 1/1. Punch-list head is now
`Thread` 17/652, `Operation` 13/125, `NSKeyedArchiver` 12/82.

## dep_class (Alamofire / Moya / Apollo)

`GUEST_NET` now includes the task types, `URLComponents`/`URLQueryItem`, and
the credential types. Re-run against `deps-census-2026-09-14.json`
(thresholds unchanged: `unsupplied_net >= 25` and `>= files/4`):

| dep | 2026-09-14 | this branch |
|---|---|---|
| Alamofire (47 files, 910 net refs) | **networking-bound** (unsupplied Task 184 + DataTask 23 + DownloadTask 23 + Credential 16 + Challenge 13 + … ≥ 25) | **Foundation-heavy** (unsupplied_net = 0) |
| Moya | Foundation-heavy | Foundation-heavy |
| Apollo | Foundation-heavy | Foundation-heavy |

Networking-bound measured deps: **1 → 0**. HAKit stays Foundation-heavy.

## Open questions

- `NSURLSession` / `NSURLRequest` / `NSHTTPURLResponse` are still ABSENT.
  A `typealias` would move them; Darwin's are classes, and no golden was
  taken for the ObjC names.
- Chunked transfer and gzip are the existing curl transport, not a new
  HTTP/1.1 decoder. Redirects 301/302/303/307/308 follow Darwin's method
  rewrite; `URLSessionTaskDelegate.willPerformHTTPRedirection` is consulted
  when the session (or `data(for:delegate:)`) has a task delegate.
- `URLProtocol.registerClass` is global and is covered by the Mach-O
  runtime test; the Focus onboarding harness still **excludes**
  `URLSession.swift` (no host URL-transport helper there).

## Verify

- `python3 full/foundation/tests/test_foundation_formatters.py` — 8 families, URLComponents 83 rows.
- `python3 full/foundation/tests/test_foundation_guest_services.py` — manifest 41; onboarding 41/40 (URLSession excluded).
- `bash full/foundation/tests/test_foundation_oracles_host.sh` — FOUNDATION_ORACLES_HOST_OK, URLComponents 83 exact.
- Catalyst **124/124**.
- iOS suite **112/113** (`corner_radius`).
- Real-app floors held **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.170 / 99.86 / 99.734 / 85.393**.
- Linux `swift:6.2-noble` `swift build -c release --product openrender` green (197.13 s).
- `scripts/linux_realapp_verify.sh /tmp/app-linux-foundation-urlsession`:
  `REAL-APP SCREEN VERIFIED ON LINUX` — headless **14/14**, live **10/10**,
  byte-identical 24/24. No-font Hello 505 px; Q miss
  `I|system-regular|17|light|F0.0|81` as expected.
- No `Package.resolved`. No pin file touched.
