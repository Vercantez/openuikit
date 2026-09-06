# GSS (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public `GSS`
Clang overlay, seeded from the Xcode 26.1 iPhoneOS 26.1 SDK. It produces one
nominal Swift module, `GSS`, and a loadable `libGSS.dylib`. It is a
**legacy-adapter** for Generic Security Service (RFC 2743/2744) plus Apple
Heimdal extensions. It is not Apple behavioral parity and it is not wired into
the shared guest package.

## What is real

- Overlay types: `OM_uint32`/`OM_uint64`, GSS handle aliases, and the six
  public C structs (`gss_OID_desc_struct`, `gss_OID_set_desc_struct`,
  `gss_buffer_desc_struct`, `gss_buffer_set_desc_struct`,
  `gss_channel_bindings_struct`, `gss_iov_buffer_desc_struct`) with memberwise
  and empty inits.
- RFC 2744 status codes, calling/routine masks, context flags, credential
  usage, address families, QOP tokens, IOV buffer types, `GSS_C_INDEFINITE`,
  `GSS_C_CRED_NO_UI`, and Apple `kGSSIC*` / `kGSSChangePassword*` dictionary
  keys (string values equal the macro names).
- OID-set and buffer-set create/add/test/release, `gss_oid_equal`,
  `gss_oid_to_str` (`"{ 1 2 840 113554 1 2 2 }"` for krb5),
  `gss_release_buffer`, and RFC 2743 APPLICATION 0 token
  encapsulate/decapsulate.
- Name import/display/compare/duplicate/release, `GSSCreateName` from
  `CFString`/`CFData`, `GSSNameCreateDisplayString`, and `gss_display_status`
  for GSS calling/routine codes.
- `GSSCreateError` returns a retained `CFError` whose code is the major
  status (domain `org.h5l.gss` on this lane).
- `gss_indicate_mechs` / `gss_iter_creds` honestly report an empty set
  (no plugins). Releasing `GSS_C_NO_CREDENTIAL` / `GSS_C_NO_NAME` is a no-op
  success.

## Fail-closed / not invented

- No Kerberos, SPNEGO, NTLM, or LKDC mechanism is registered.
  `gss_acquire_cred`, password acquire, and Apple `gss_aapl_initial_cred`
  return `GSS_S_NO_CRED`.
- `gss_init_sec_context` / `gss_accept_sec_context` return
  `GSS_S_UNAVAILABLE` and never emit a token.
- Wrap, unwrap, MIC, PRF, wrap-size, and inquire-context on a handle return
  `GSS_S_NO_CONTEXT`. Canonicalize-name / names-for-mech return
  `GSS_S_BAD_MECH`. Export-name of a non-MN returns `GSS_S_NAME_NOT_MN`.
- `gss_userok` returns 0. Krb5 ccache/lucid/enctype/authz/acceptor-identity
  APIs return `GSS_S_UNAVAILABLE`. UUID credential lookup returns nil.
- `gss_aapl_change_password` returns `GSS_S_UNAVAILABLE` with a `CFError`.

## Still deferred

No public-surface identifier is deferred: all 248 exact IDs are
`implemented` with a focused `test*` function. Remaining Apple questions
live in `oracle-questions.tsv`.

Isolated compile (this environment) can import `CoreFoundation`. Run the
immutable host gate:

```sh
bash tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Campaign `ios26.1-fwseed-r14`, lane `legacy-adapter`, framework `GSS`
(248 IDs). Starting commit `26f5086c5b31ba816742f18d3096152cd32280f4`.

| | implemented | declared | deferred |
|---|---:|---:|---:|
| Seed | 0 | 0 | n/a (no coverage yet) |
| After this pass | **248** | **0** | **0** |

Nondeferred 248. Every `implemented` row cites
`test:full/gss/tests/agent/<File>Tests.swift#testName` for a real
top-level synchronous no-argument `func testName()`.

Top-5 evidence distribution (implemented rows → test):

1. `testGSSStatusCodes` — 25 (RFC 2744 `GSS_S_*` raw values, including aliases)
2. `testGSSAddressFamilies` — 23 (`GSS_C_AF_*`)
3. `testGSSAppleDictionaryKeys` — 20 (`kGSSIC*` / password-change keys)
4. `testGSSPointerTypealiases` — 16 (OID/buffer/channel/IOV pointer aliases)
5. `testGSSUsageAndQOP` — 13 (usage, QOP, PRF, `GSS_C_INDEFINITE`, option mask)

Host gate markers from `bash full/gss/tests/acceptance/test_host.sh`:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=GSS lane=legacy-adapter symbols=248
FRAMEWORK_FANOUT_REFERENCE_OK
GSS_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=GSS dylib=libGSS.dylib
```

`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`). `swiftc` is
Swift 6.2.4 / linux and the sealed gate compiles with a clean product tree
(`products=clean`).
