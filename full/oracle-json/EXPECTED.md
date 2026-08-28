# Pre-registered expectations — written before the port was ever run

**This file is committed in its own commit, before `json_runner.swift` exists,
so that the ordering is checkable in `git log` rather than asserted here.**
Everything below is derived either from reading swift-foundation's source or
from the golden's own two *Apple* columns. Neither involves the port.

The precedent is #72's URL oracle, where a pre-registered "16 rows are
expected-fail" turned out to be **7**, and the only reason anyone found out was
that the runner carried an alarm saying `IDNA rows that matched must be 0`. So
every class below is stated as a **defining property** — the thing that causes
the divergence — never as a signature of the output, and each one gets a
condition that can prove it wrong.

---

## First, the fact that changes what this oracle can claim

`URL` was a genuine cross-implementation test: the golden came from Darwin's
`_BridgedURL` (NSURL-backed) and the port is `_SwiftURL`. **JSON is not the
same situation, and pretending otherwise would be the finding here.**

Measured on this machine (macOS 26.5.2, build 25F84), `JSONDecoder().decode(_:from: "{")`
reports:

```
DecodingError.dataCorrupted: Data was corrupted. Debug description: The given
data was not valid JSON.. Underlying error: Error Domain=NSCocoaErrorDomain
Code=3840 "Unexpected end of file"
```

That string is assembled by three specific lines of the source we compile:
`JSONDecoder.swift:393` (the wrapper text), `JSONScanner.swift:1308` (the
`unexpectedEndOfFile` description) and `JSONScanner.swift:1381-1386` (the
`CustomNSError` conformance that produces `NSCocoaErrorDomain` / 3840). The
`JSONSerialization` path, by contrast, says `"Unexpected end of file during
JSON parse. around line 1, column 0."` and carries `NSJSONSerializationErrorIndex`
— a different code path with different words.

**So macOS's `JSONDecoder` IS swift-foundation's `JSONDecoder`.** The golden
therefore has three columns and only two implementations:

| | what it is | independent of the port? |
|---|---|---|
| **A** `JSONSerialization` | Darwin's closed-source CF parser. Not in swift-foundation, not in the port. | **yes** |
| **B** `JSONDecoder` | swift-foundation, built by Apple. Same source we compile. | no — same source |
| **C** the port | swift-foundation `release/6.2.2`, our build. | — |

* **C vs B** isolates the *build and the stack*: toolchain, SDK, target,
  `libswiftcompat`, and (on the guest route) machorun. It is **not** evidence
  that two implementations agree.
* **C vs A** is the cross-implementation comparison, and it is the one that can
  be quoted the way "802 of 802" was.

## Second, the version-skew hazard, stated because it cannot be eliminated

macOS 26.5.2 ships *some* revision of swift-foundation; we compile
`release/6.2.2` = `c6793ef`. Those are not guaranteed identical. **Any C-vs-B
divergence is therefore either a build defect or upstream skew, and the two are
distinguished by reading the upstream diff for the file involved — not by
which answer looks nicer.** No divergence may be labelled "skew" without
naming the upstream change.

---

## The classes

### P1 — error TEXT is recorded and never scored *(rule, not a prediction)*

`errorKind()` in `json_canon.swift` reduces an error to its `DecodingError`
case plus its `codingPath`. `dec_err_text` is stored beside it and is reported
as a free side-measurement. Two builds of one parser may word a message
differently; they may not disagree about whether a failure was `dataCorrupted`
or `typeMismatch`, or about where in the document it happened.

**Falsifier:** if the text agreement rate is 100%, the run says so, and the
distinction cost nothing. If it is below 100%, the differing texts are printed.

### P2 — number type inference: expected to differ **from A only**

`JSONSerialization` decides int-vs-double from the *spelling*; swift-foundation
decides from the *value*. Measured in the golden, A vs B, before the port ran:

| document | A (`JSONSerialization`) | B (`JSONDecoder`) |
|---|---|---|
| `{"v":1.0}` | `D3ff0000000000000` | `I1` |
| `{"v":1e2}` / `1E2` / `1e+2` | `D4059000000000000` | `I100` |
| `{"v":1e007}` | `D416312d000000000` | `I10000000` |
| `{"v":-0.0}` | `D8000000000000000` (sign kept) | `I0` (sign lost) |
| `{"v":1e-400}` | `D0000000000000000` | `I0` |
| `eidolon/Kiosk/Stubbed Responses/Auctions.json` | `width=D4061800000000000` | `width=I140` |

That last row is the one that matters: **`"width":140.0` in a shipping app's
committed fixture**, not an invented case. Nine golden documents are in this
class (eight synthetic, one real).

**Prediction: C matches B exactly on all nine, and differs from A on all nine.**
**Falsifier:** a row where C matches A. That would mean C is not the code B is.

### P3 — top-level fragments: expected to differ **from A only**

`JSONSerialization` without `.fragmentsAllowed` rejects a document whose root
is not an object or array; `JSONDecoder` accepts one. Measured: **exactly 7
documents** (`frag/top-string`, `-number`, `-negative`, `-true`, `-false`,
`-null`, `-string-empty`), all synthetic — the real corpus contains **zero**
top-level fragments, which is itself worth knowing. All 7 parse under A when
`.fragmentsAllowed` is set, which is why the golden records that column too.

**Prediction: C matches B (accepts all 7) and matches A-with-fragments.**

### P4 — depth limits: expected to be IDENTICAL, and this is the surprise

The obvious prediction was that a closed-source CF parser and a Swift rewrite
stop at different depths. **Measured, they do not.** Both accept 512 and both
reject 513, on arrays and on objects, and both report the same error class:

```
depth/array-512  A ok   B ok        depth/array-513  A 3840   B dataCorrupted@
depth/object-512 A ok   B ok        depth/object-513 A 3840   B dataCorrupted@
```

So depth is **not** a pre-registered divergence. It is recorded here because it
was a candidate and measurement removed it — a class assumed rather than
measured would have been carried into the scoreboard as noise.

Separately, and asymmetrically: **`JSONEncoder` refuses to re-encode a
512-deep value** that `JSONDecoder` just accepted (`invalidValue@`, 2 rows). The
decoder's ceiling and the encoder's are not the same number, inside one library.

### P5 — everything else: C must equal B **exactly**, zero divergences

Because B is the same source, the prediction for the host route is not
"high agreement". It is **zero rows differing** on `dec_ok`, `dec_canon`,
`dec_err` (type + path), `enc_ok`, `enc_out`, and all 43 Codable probes.

**This is the strongest falsifier in the file.** A single C-vs-B divergence is
a finding about our build configuration or about upstream skew, and must be
named as one of the two — not absorbed into a percentage.

### P6 — host vs guest: any difference is a STACK finding

The two routes compile the same 202 sources. The host binary is Apple-toolchain
native; the guest is a Mach-O under machorun linking `libswiftcompat`. Per the
#66 ruling the golden is the oracle, so the binaries need not match — but
**the two scoreboards must**. A row that passes on the host and fails in the
guest is machorun's, not the port's, and gets its per-component diff printed.

### P7 — a `fm_unimplemented.c` stub firing is a finding, not a failure

32 of the 36 stubbed C symbols abort loudly naming themselves on fd 2.
`JSONDecoder` has no business touching the file surface; the runner reads with
`read(2)` and decodes from memory precisely so that any stub that fires is
attributable. **If one fires, the run reports which, and that is a result about
the port's dependencies, not a broken run to be worked around.**

---

## Two known, accepted weaknesses, stated now rather than discovered later

1. **The runner parses its own inputs with the decoder under test.** The corpus
   and golden are read with the port's `JSONDecoder`. A decoder broken enough
   to mis-read them cannot score itself. Mitigations: the corpus file is plain
   ASCII (documents are base64), the runner prints both counts and refuses to
   score if they disagree, and it re-checks each document's decoded length
   against the `bytes` the corpus declares.

2. **Canon values longer than 4096 bytes are stored as `#<len>:<fnv1a64>`.**
   A divergence on such a row is still detected but reports a length and a
   hash rather than a position. The affected rows are a named minority and the
   runner prints how many of the rows it scored were digested.
