# URL differential oracle

The golden file any `URL` implementation must match — whether it ends up backed
by CFURL or written in portable Swift. Built the way every oracle in this
project is built: run the real thing, record what it says, diff against it.

    swiftc -O -o url_oracle url_oracle.swift          # macOS, real Foundation
    ./url_oracle url-corpus-2026-08-27.json > golden.json

## Why this exists before any implementation

#58 was framed as "surface Swift APIs over CF bridge classes that already
exist". **That premise does not hold yet** (2026-08-27): `foundation-macho`
builds **no dylib at all**, and its 20 `__NSCF*` classes were harvested from
**7 object files** — its own `ns-classes.txt` says so, "a name here means the
compiler emitted `_OBJC_CLASS_$_<name>` as a DEFINED symbol". CF waits on
libdispatch, which waits on 29 libSystem symbols (#60).

So the implementation is blocked on someone else's queue, but **the oracle is
not**, and it is needed identically either way. Building it now also spent the
app corpus while it existed — 723 MB of shallow clones in a session scratchpad
that evaporates.

## The corpus is real app source, not invented cases

809 distinct URL-ish string literals harvested from `URL(string: "…")` call
sites and URL-shaped literals across eidolon, DuckDuckGo iOS, ios-oss and
pocket-casts-ios. Invented edge cases test what an author imagined; these test
what four shipping apps actually contain.

## What it already pins, each of which a plausible implementation gets wrong

| input | real Foundation says | the naive answer |
|---|---|---|
| `HTTPS://pca.st` | scheme `HTTPS` | lowercased to `https` |
| `/bad/url` | **parses**, scheme nil, path `/bad/url` | `nil` |
| `a/b` | parses as a relative URL | `nil` |
| `about:blank` | scheme `about`, host nil, path `blank` | host `blank` |
| `blob:https://www.my.com/…` | scheme `blob`, path holds the nested URL | mis-split |

**All 809 parse. 78 have no scheme and 99 have no host.** A `URL(string:)` that
returns nil for schemeless input — the obvious reading of "is this a valid
URL?" — would fail on 78 of 809 real-world inputs.

## Fields recorded

`absoluteString`, `scheme`, `host`, `port`, `path`, `query`, `fragment`,
`user`, `password`, `relativePath`, `isFileURL`, `lastPathComponent`,
`pathExtension`, `pathComponents`, plus the two path operations the census
ranks highest: `appendingPathComponent("x")` and `deletingLastPathComponent()`.

Field choice follows the member census (`full/census/`): `absoluteString`
19.3%, `appendingPathComponent` 12.9%, `host` 11.8%, `path` 11.1%, `query`
8.3% — the top five are 63.4% of all URL member uses.

## 16 rows are EXPECTED-FAIL without FoundationInternationalization

`URLParser.swift` declares `_uidnaHook()` as a `dynamic package func` returning
`UIDNAHook.Type?`. `FoundationInternationalization` overrides it; without that
module it returns **nil**, and IDNA/punycode encoding of non-ASCII hostnames is
skipped. `URL` itself works fine — this is a scope boundary of the port, not a
defect in it.

Measured against this corpus rather than assumed: **7 inputs contain non-ASCII
characters and 16 rows carry punycode output**, e.g.

    http://💩.la              ->  host = xn--ls8h.la
    https://💩.la:8080        ->  host = xn--ls8h.la

(Those come from DuckDuckGo's own test data — a real IDNA case, better than one
we would have invented.)

**So the 16 `xn--` rows must be marked expected-fail and not chased**, until and
unless `FoundationInternationalization` is ported too. A run that "fixes" them
without that module has done something wrong. Everything else in the 809 is a
genuine acceptance criterion.
