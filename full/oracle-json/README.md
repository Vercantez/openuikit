# JSON / Codable differential oracle

The golden file any `JSONDecoder`, `JSONEncoder` and `Codable` implementation
must match. Built the way every oracle here is built — run the real thing,
record what it says, diff against it — and extending the method of
[`../oracle-url/`](../oracle-url/README.md) to the model layer's second-largest
surface (`Decodable` 294 uses, `CodingKeys` 292, `JSONDecoder` 113 in
`../census/model-census-2026-08-27.json`).

    ./build_corpus.sh <dir-with-the-four-clones>      # corpus + golden, macOS
    ../foundation/build_json_host.sh                  # host route  (the PORT)
    ../foundation/build_json_runner.sh                # guest route (the STACK)

---

## Read this before reading any number: what this oracle can and cannot claim

`URL` was a genuine cross-implementation test — Darwin's `URL` is normally
`_BridgedURL`, NSURL-backed, and the port is `_SwiftURL`. **JSON is not that
situation**, and the whole design here follows from measuring it rather than
assuming it.

macOS 26.5.2's `JSONDecoder` **is swift-foundation's `JSONDecoder`.** Its error
for the input `{` is

```
DecodingError.dataCorrupted: … The given data was not valid JSON.. Underlying
error: Error Domain=NSCocoaErrorDomain Code=3840 "Unexpected end of file"
```

which is assembled by three specific lines of the source this port compiles:
`JSONDecoder.swift:393`, `JSONScanner.swift:1308`, and the `CustomNSError`
conformance at `JSONScanner.swift:1381-1386`. `JSONSerialization`, by contrast,
says `"Unexpected end of file during JSON parse. around line 1, column 0."` and
carries `NSJSONSerializationErrorIndex` — a different code path, different
words.

So the golden has **three columns and two implementations**:

| | what it is | independent of the port? |
|---|---|---|
| **A** `JSONSerialization` | Darwin's closed-source CF parser. Not in swift-foundation, not in the port. | **yes** |
| **B** `JSONDecoder` | swift-foundation, built by Apple. The same source we compile. | no |
| **C** the port | swift-foundation `release/6.2.2`, our build, both routes. | — |

* **C vs B is a build-and-stack differential.** Zero divergences means our
  toolchain, SDK, target and (in the guest) machorun reproduce Apple's build of
  the same code. It is **not** two implementations agreeing.
* **C vs A is the cross-implementation comparison**, and it is the one that can
  be quoted the way "802 of 802" was.

[`EXPECTED.md`](EXPECTED.md) pre-registers the divergence classes and was
committed in `d10ca09`, **before `json_runner.swift` existed** — the ordering
is in `git log`, not asserted.

---

## The corpus: 224 real + 139 synthetic, denominated separately, always

| | |
|---|---|
| real | **224** documents, from `artsy/eidolon`, `duckduckgo/iOS`, `kickstarter/ios-oss`, `Automattic/pocket-casts-ios` — 118 / 60 / 24 / 22 |
| by kind | 150 committed `.json` files, 70 Swift triple-quoted literals, 4 single-line literals |
| synthetic | **139** labelled edges (`gen_synthetic.py`), covering what the real set demonstrably does not reach |
| total | 363 documents, 576,114 raw bytes |
| selection | 2,832 raw candidates → 2,176 unique by content → 224, chosen rarest-feature-first under per-feature quotas, not sampled uniformly |

Documents are stored **base64**, because a JSON corpus has to carry documents
that are not valid JSON (truncated, bad escapes, invalid UTF-8), and because it
keeps the corpus *file* plain ASCII — the runner's own decoder is the thing
under test and must always be able to load its inputs.

**Uniform sampling would have returned 300 near-identical `Contents.json`
files**, since that is what 2,600 of the 2,832 candidates are. The selection
optimises for covering every feature the corpus *has*.

### The harvester was wrong once, and the way it was wrong is worth keeping

`.js` was in the source-extension list. DuckDuckGo vendors a minified
autoconsent bundle whose string literals are CSS selectors — `[role=tablist]`,
`[data-cookie-accept-all]` — every one of which starts with `[`, ends with `]`,
and fails to parse. Sixty-odd of them arrived labelled *"real malformed JSON
from a shipping app"* and were nothing of the kind. `.js` is gone and one-line
literals must now parse to be admitted; multi-line literals and `.json` files
still need not, which is where the genuinely broken documents come from.

Swift-unescaping is applied to multi-line literals too. Skipping it *invents*
malformity: source `\\"` is a correct JSON escape and would have been recorded
as a backslash followed by a bare quote.

---

## Finding: Foundation accepts trailing commas, and 16 real documents need it

Seventeen of the 224 real documents are rejected by Python's `json` (and by RFC
8259). **Foundation rejects exactly one of them.**

| | |
|---|---|
| `iOS/DuckDuckGoTests/MockFiles/invalid.json` = `{[}` | rejected by both A and B |
| the other **16** | **accepted by both A and B** — all sixteen are trailing commas |

Confirmed three independent ways: in the golden's two columns, in the synthetic
controls, and in a six-line program:

```
{"a":1,}      JSONDecoder=true   JSONSerialization=true
[1,2,]        JSONDecoder=true   JSONSerialization=true
[1,2,,]       JSONDecoder=false  JSONSerialization=false
{"a":1,,}     JSONDecoder=false  JSONSerialization=false
[,1]          JSONDecoder=false  JSONSerialization=false
```

One trailing comma before a closing bracket is accepted; two, a leading comma,
and a missing comma are not. **A strictly RFC-8259 parser would fail on 16 of
224 real-world documents (7%)** — including `privacy-config-example.json`, a
DuckDuckGo test fixture, and a Kickstarter GraphQL `.json` template. This is
the JSON counterpart of the URL oracle's "a `URL(string:)` that returns nil for
schemeless input fails on 78 of 809".

It also means "malformed" is the wrong word for those sixteen. They are
documents *Python* rejects and *Foundation* accepts.

---

## What "equal" means

`json_canon.swift` is compiled into **both** the oracle and the runner, because
a canonicalisation described in a README and implemented twice is two
canonicalisations. Read its header for the reasoning; the alphabet is:

```
null N   bool T/F   Int64 I<dec>   UInt64 U<dec>   Double D<16 hex bit-pattern>
string S<scalar count>:<escaped>   array [a,b]   object {K=V,K=V}, keys sorted by UTF-8 bytes
```

* **Doubles compare by bit pattern**, so `0.0 ≠ -0.0` and no float *formatting*
  difference can ever be mistaken for a parse difference.
* **The scalar type is part of the value**: `1` and `1.0` are not equal, because
  which Swift type a JSON number becomes is the single thing two JSON
  implementations most often disagree about.
* **Duplicate keys are already collapsed** by the time we canonicalise. Which
  value survived is the observable.
* **Known and accepted**: Swift `String` equality is canonical equivalence, so
  two canonically-equivalent-but-differently-composed keys collapse to one
  entry. Both sides are Swift, so it cancels — but it means the canon is a
  statement about Swift's string model, not about JSON's.
* **Error TYPE and coding path are scored; error TEXT never is.** That rule was
  pre-registered and it earned its place (see below).
* Canon values over 4,096 bytes are stored as `#<len>:<fnv1a64>`. **46 of 363
  rows** are compared this way; the runner prints that count. Detection is
  unaffected; a failing digested row reports a length and a hash instead of a
  position.

---

## Scoreboards

Both routes, three runs each, byte-identical output within each route.

```
documents scored             363 of 363   (46 compared by digest)

C vs B  (same source; build+stack differential)
  identical                  363 of 363
  differing                  0 of 363   (must be 0)
  error TEXT also identical  8 of 61 failing rows   (host)   -- recorded, NOT scored
                             0 of 61 failing rows   (guest)  -- recorded, NOT scored

C vs A  (JSONSerialization; cross-implementation)
  agree                      345 of 345 rows where A and B agree
  unexpected divergence      0 of 345   (must be 0)
  expected divergence        18 of 18 confirmed
  expected rows that matched 0 of 18   (must be 0)

Codable probes
  identical to golden        43 of 43
  differing                  0 of 43   (must be 0)

VERDICT: all six conditions hold.
```

| route | what it is | script | binary sha256 |
|---|---|---|---|
| host | Apple toolchain, Apple SDK, native | `../foundation/build_json_host.sh` | `74dfea19…802c2dda` |
| guest | Mach-O under machorun on Linux, root `scratch/mrroot_fe` | `../foundation/build_json_runner.sh` | `aff119bd…5c4da5a33` |

### The expected-divergence set is read out of the golden, not listed in code

A row is an expected C-vs-A divergence **iff the two Apple columns already
disagreed on it** — a fact established and committed before the runner existed.
The runner recomputes that set at run time and carries two alarms that would
prove the classifier wrong rather than the port: *a row where A and B agreed and
C disagrees with both* (0), and *a row where A and B disagree and C matched A
anyway* (0, and impossible if C really is B's source).

The 18, with their causes:

* **9 — number type inference.** `JSONSerialization` decides int-vs-double from
  the *spelling*; swift-foundation from the *value*. `{"v":1e2}` is
  `D4059000000000000` to A and `I100` to B and C. `-0.0` **keeps its sign in CF
  and loses it in Swift** (`D8000000000000000` vs `I0`). One of the nine is
  real: **eidolon's `Auctions.json` ships `"width":140.0`**, and that single
  token is the entire difference between the two 5-KB canons.
* **1 — double parsing precision.** `0.123456789012345678901234567890` parses to
  `D3fbf9add3746f663` under CF and `D3fbf9add3746f65f` under swift-foundation.
  Four ULP apart, in two of Apple's own parsers.
* **1 — overflow asymmetry.** `-1e309` parses to `-inf` under CF and **fails**
  under swift-foundation, while `+1e309` fails under both.
* **7 — top-level fragments.** `JSONSerialization` without `.fragmentsAllowed`
  rejects a root that is not an object or array; `JSONDecoder` accepts one. All
  seven are synthetic: **the real corpus contains zero top-level fragments.**

### A pre-registered class that measurement removed

Depth limits were an obvious candidate and **they are identical**: both
implementations accept 512 and reject 513, arrays and objects alike, with the
same error class. A class assumed rather than measured would have entered the
scoreboard as noise.

Separately and asymmetrically: **`JSONEncoder` refuses to re-encode a 512-deep
value that `JSONDecoder` had just accepted** (`invalidValue@`, 2 rows). One
library, two different ceilings.

---

## The error-text column, and why it was right not to score it

P1 said compare the error *type* and *coding path*, never the text. Measured,
the text agrees on only **8 of 61** failing rows on the host and **0 of 61** in
the guest. Two separate causes, both worth naming:

**1. `underlyingError` is a `FOUNDATION_FRAMEWORK` conditional.**
`JSONDecoder.swift:387-392` reads

```swift
#if FOUNDATION_FRAMEWORK
let underlyingError: Error? = error.nsError
#else
let underlyingError: Error? = nil
#endif
```

Apple's build sets that flag; ours does not, so 53 of 61 messages lose their
`Underlying error: … NSCocoaErrorDomain Code=3840 …` tail. This is a **scope
boundary of the port**, exactly like `_uidnaHook` was for URL — not a defect,
and invisible to any scored column.

**2. Host and guest render a `DecodingError` differently, and it is not the
port's doing.** Isolated to a four-line program containing no port code and
importing no Foundation at all:

```
native (Apple toolchain)   DecodingError.dataCorrupted: Data was corrupted. Debug description: …
Mach-O guest (machorun)    dataCorrupted(Swift.DecodingError.Context(codingPath: [], …, underlyingError: nil))
```

**Attribution, stated to the limit of what was measured and no further.** The
native binary's `LC_LOAD_DYLIB` list is `libSystem` + `libswiftCore` only — yet
`DYLD_PRINT_LIBRARIES` shows it loading **1,155 images, among them
`Foundation.framework` and `CoreFoundation`**. Foundation's retroactive
conformances on `DecodingError` are therefore present for dynamic lookup in any
macOS process whether or not the binary links Foundation. The guest process has
**13** dylibs and none of them is Foundation. That is a difference of *process
environment*; whether the rendering comes from Foundation's conformances or
from a difference between Apple's libswiftCore and the cross-built one was **not
isolated further**, because the discriminating experiment — a macOS process with
Foundation excluded — is not available.

**The consequence is methodological and belongs in this README rather than in a
footnote: the host route does not isolate the port as cleanly as
`build_fe_host.sh`'s header claims.** A host process carries all of Darwin
Foundation and can satisfy a dynamic conformance lookup from it. It changed no
scored value here. It is exactly the class of thing that would not announce
itself if it did.

---

## Teeth, all checked rather than assumed

| | |
|---|---|
| the guest binary run **without** machorun | `cannot execute binary file: Exec format error`, exit 126 — the scoreboard could only have come from the loader |
| a **truncated corpus** | the runner dies (exit 133) rather than scoring a subset |
| **one document altered** (`syn-0009`: `{"v":1.0}` → `{"v":2.0}`, same length, `bytes` unchanged) | `FAIL syn-0009`, `differing 1 of 363`, `VERDICT: at least one condition failed`, **exit 1 on both routes** |
| corpus/golden row counts, ids and per-document byte counts | checked before scoring; a mismatch exits 2 without a scoreboard |

---

## Pins, because a number without its configuration is not a measurement

| | |
|---|---|
| corpus / golden | `json-corpus-2026-08-27.json`, `json-golden-2026-08-27.json`, generated **2026-08-27** |
| golden produced on | macOS **26.5.2 (Build 25F84)** — recorded in the golden's own `macos` field |
| pre-registration commit | `d10ca09` (corpus + golden + `EXPECTED.md`, before the runner existed) |
| swift-foundation | `release/6.2.2` = `c6793ef` |
| swift-collections | **1.1.3** = `9bf03ff` (from `update-checkout-config.json` at `swift-6.2.2-RELEASE`, not the `from: "1.1.0"` range) |
| target | `arm64-apple-macos15.0` — raises the deployment floor of everything linking the module |
| FoundationEssentials.o | host `12,535,568` bytes (2026-08-27 19:13:35), guest `12,152,024` bytes (2026-08-28 00:12:48) — both built by `build_fe.sh` / `build_fe_host.sh`, neither by this oracle |
| host runner sha256 | `74dfea195d4dbae6aa2f6473171ba34489ada43b4c43d3c1b01d1472802c2dda` |
| guest runner sha256 | `aff119bd0e1c5d86394998a3330a01d00d18be9f301915f9deab0ae5c4da5a33` |
| machorun | HEAD `a73f1df`, loader sha256 `d702b819…fac35eaaa`, **identical before and after the guest runs** |
| guest root | `scratch/mrroot_fe`, 21 dylibs + loader; **all 22 digests unchanged across every guest run** (a concurrent agent was working in `~/machorun`, so the bracket is the evidence the runs were not raced) |
| `mrroot_fe` manifest | **still absent** — task #75's known gap. The guest runs used the explicit-`MACHORUN_ROOT` passthrough. The root was **not** refreshed; `require_fresh_root`'s refresh destroyed a root once. |

**The corpus is not byte-reproducible and the golden is.** The clones are HEAD,
so a later harvest sees later commits; what reproduces is the method, and every
document carries its `origin`. The golden is a pure function of the corpus plus
the macOS Foundation named above.
