#!/usr/bin/env python3
"""gen_synthetic.py -- the labelled edge cases the four apps happen not to ship.

    ./gen_synthetic.py <out-synthetic.json>

DENOMINATED SEPARATELY FROM THE REAL SET, always, and the reason is the whole
argument for a real corpus: invented cases test what an author imagined.  The
real set (`harvest_json.py`) is the acceptance criterion; this set is a probe
of edges the real set demonstrably does not reach -- MEASURED from the real
corpus's own feature histogram, not guessed:

    uescape 1 document, bigint 4, longfrac 3, surrogate 0, invalid-utf8 0,
    escaped-slash 0, top-fragment 0, depth > 12 zero.

Every document here carries a `label` naming the property it probes, so a
failure says what broke rather than which index broke.
"""
import base64, json, sys

DOCS = []


def add(label, payload, note=""):
    if isinstance(payload, str):
        payload = payload.encode("utf-8")
    DOCS.append((label, payload, note))


# ---- numbers --------------------------------------------------------------
add("num/int64-max", '{"v":9223372036854775807}')
add("num/int64-min", '{"v":-9223372036854775808}')
add("num/int64-max-plus-1", '{"v":9223372036854775808}',
    "no longer Int64; UInt64 or Double is the question")
add("num/uint64-max", '{"v":18446744073709551615}')
add("num/uint64-max-plus-1", '{"v":18446744073709551616}')
add("num/int32-max", '{"v":2147483647}')
add("num/zero", '{"v":0}')
add("num/negative-zero-int", '{"v":-0}', "sign of zero survives or does not")
add("num/negative-zero-double", '{"v":-0.0}')
add("num/one-point-zero", '{"v":1.0}', "integral-valued double: Int or Double?")
add("num/exponent-lower", '{"v":1e2}')
add("num/exponent-upper", '{"v":1E2}')
add("num/exponent-plus", '{"v":1e+2}')
add("num/exponent-minus", '{"v":1e-2}')
add("num/exponent-zero-pad", '{"v":1e007}')
add("num/exponent-huge", '{"v":1e309}', "overflows Double: +inf, or an error?")
add("num/exponent-huge-neg", '{"v":-1e309}')
add("num/exponent-tiny", '{"v":1e-400}', "underflows Double to zero")
add("num/exponent-absurd", '{"v":1e1000000}')
add("num/double-max", '{"v":1.7976931348623157e308}')
add("num/double-min-subnormal", '{"v":5e-324}')
add("num/precision-30-digits", '{"v":0.123456789012345678901234567890}')
add("num/precision-40-int-digits", '{"v":12345678901234567890123456789012345678901}')
add("num/point-one", '{"v":0.1}')
add("num/point-three", '{"v":0.3}')
add("num/two-thirds", '{"v":0.6666666666666666}')
add("num/big-frac-and-exp", '{"v":-1.2345678901234567e-17}')
add("num/leading-zero", '{"v":01}', "INVALID per RFC 8259")
add("num/leading-plus", '{"v":+1}', "INVALID")
add("num/bare-decimal-point", '{"v":.5}', "INVALID")
add("num/trailing-decimal-point", '{"v":5.}', "INVALID")
add("num/empty-exponent", '{"v":1e}', "INVALID")
add("num/lone-minus", '{"v":-}', "INVALID")
add("num/hex", '{"v":0x10}', "INVALID (JSON5 only)")
add("num/nan-literal", '{"v":NaN}', "INVALID")
add("num/infinity-literal", '{"v":Infinity}', "INVALID")
add("num/double-minus", '{"v":--1}', "INVALID")

# ---- unicode --------------------------------------------------------------
add("uni/escape-bmp", '{"v":"\\u00e9\\u4e2d\\u0041"}')
add("uni/escape-uppercase-hex", '{"v":"\\u00E9"}')
add("uni/surrogate-pair", '{"v":"\\ud83d\\ude00"}', "U+1F600, correctly paired")
add("uni/lone-high-surrogate", '{"v":"\\ud800"}', "MALFORMED: unpaired high")
add("uni/lone-low-surrogate", '{"v":"\\udc00"}', "MALFORMED: unpaired low")
add("uni/reversed-surrogate-pair", '{"v":"\\ude00\\ud83d"}', "MALFORMED")
add("uni/high-surrogate-then-ascii", '{"v":"\\ud800a"}', "MALFORMED")
add("uni/high-surrogate-at-end", '{"v":"a\\ud83d"}', "MALFORMED")
add("uni/escaped-nul", '{"v":"\\u0000"}')
add("uni/escaped-del", '{"v":"\\u007f"}')
add("uni/noncharacter-ffff", '{"v":"\\uffff"}')
add("uni/replacement-char", '{"v":"\\ufffd"}')
add("uni/raw-utf8-2byte", '{"v":"\u00e9"}')
add("uni/raw-utf8-3byte", '{"v":"\u4e2d\u6587"}')
add("uni/raw-utf8-4byte", '{"v":"\U0001f4a9"}')
add("uni/raw-invalid-utf8", b'{"v":"\xff\xfe"}', "MALFORMED: not UTF-8 at all")
add("uni/truncated-utf8", b'{"v":"\xe4\xb8"}', "MALFORMED: 3-byte seq cut short")
add("uni/overlong-utf8", b'{"v":"\xc0\xaf"}', "MALFORMED: overlong '/'")
add("uni/lone-continuation", b'{"v":"\x80"}', "MALFORMED")
add("uni/bom-prefix", b'\xef\xbb\xbf{"v":1}', "UTF-8 BOM before the document")
add("uni/utf16le-bom", b'\xff\xfe{\x00"\x00v\x00"\x00:\x001\x00}\x00',
    "UTF-16LE with BOM: JSON permits it, the API may not")
add("uni/escape-short", '{"v":"\\u00"}', "MALFORMED: 2 hex digits")
add("uni/escape-nonhex", '{"v":"\\uzzzz"}', "MALFORMED")
add("uni/bad-escape-letter", '{"v":"\\x41"}', "MALFORMED: \\x is not JSON")
add("uni/bad-escape-single-quote", "{\"v\":\"\\'\"}", "MALFORMED")
add("uni/trailing-backslash", '{"v":"abc\\"}', "MALFORMED: escapes the quote")
add("uni/escaped-solidus", '{"v":"a\\/b"}', "legal, and rarely round-trips")
add("uni/all-simple-escapes", '{"v":"\\"\\\\\\/\\b\\f\\n\\r\\t"}')
add("uni/raw-newline-in-string", '{"v":"a\nb"}', "MALFORMED: raw control char")
add("uni/raw-tab-in-string", '{"v":"a\tb"}', "MALFORMED")
add("uni/long-string-4k", '{"v":"' + "x" * 4096 + '"}')
add("uni/combining-marks", '{"v":"e\u0301\u0327"}')
add("uni/rtl", '{"v":"\u0645\u0631\u062d\u0628\u0627"}')
add("uni/emoji-zwj", '{"v":"\U0001f469\u200d\U0001f4bb"}')

# ---- structure ------------------------------------------------------------
add("struct/empty-object", "{}")
add("struct/empty-array", "[]")
add("struct/nested-empties", '{"a":{},"b":[],"c":[{}],"d":[[]]}')
add("struct/dup-key-2", '{"a":1,"a":2}', "last wins, first wins, or error?")
add("struct/dup-key-3", '{"a":1,"a":2,"a":3}')
add("struct/dup-key-type-change", '{"a":1,"a":"two"}')
add("struct/dup-key-null-then-value", '{"a":null,"a":5}')
add("struct/empty-key", '{"":1}')
add("struct/dup-empty-key", '{"":1,"":2}')
add("struct/key-with-escapes", '{"a\\nb":1,"a\\u0062":2}')
add("struct/key-unicode", '{"\u4e2d":1}')
add("struct/whitespace-heavy", ' \t\r\n { \t\r\n "a" \t : \t 1 \t } \t\r\n ')
add("struct/no-whitespace", '{"a":[1,2,{"b":null}]}')
add("struct/trailing-newline", '{"a":1}\n')
add("struct/trailing-whitespace-only", '{"a":1}   \t\n')
add("struct/trailing-garbage", '{"a":1}x', "MALFORMED")
add("struct/two-documents", '{"a":1}{"b":2}', "MALFORMED")
add("struct/leading-garbage", 'x{"a":1}', "MALFORMED")
add("struct/trailing-comma-object", '{"a":1,}', "MALFORMED (17 of 18 real ones)")
add("struct/trailing-comma-array", '[1,2,]', "MALFORMED")
add("struct/leading-comma", '[,1]', "MALFORMED")
add("struct/double-comma", '[1,,2]', "MALFORMED")
add("struct/missing-comma", '{"a":1 "b":2}', "MALFORMED")
add("struct/missing-colon", '{"a" 1}', "MALFORMED")
add("struct/unquoted-key", '{a:1}', "MALFORMED (JSON5 only)")
add("struct/single-quoted", "{'a':1}", "MALFORMED (JSON5 only)")
add("struct/line-comment", '{"a":1} // hi', "MALFORMED (JSON5 only)")
add("struct/block-comment", '{/*x*/"a":1}', "MALFORMED (JSON5 only)")
add("struct/unclosed-object", '{"a":1', "MALFORMED: truncated")
add("struct/unclosed-array", '[1,2', "MALFORMED: truncated")
add("struct/unclosed-string", '{"a":"b', "MALFORMED: truncated")
add("struct/truncated-in-key", '{"ab', "MALFORMED")
add("struct/truncated-in-number", '{"a":12', "MALFORMED")
add("struct/truncated-in-literal", '{"a":tru', "MALFORMED")
add("struct/mismatched-brackets", '{"a":1]', "MALFORMED")
add("struct/close-only", '}', "MALFORMED")
add("struct/empty-input", "", "MALFORMED: zero bytes")
add("struct/whitespace-only", "   \n\t ", "MALFORMED")
add("struct/nul-only", b"\x00", "MALFORMED")

# top-level fragments: JSONDecoder allows them, JSONSerialization historically
# needed .fragmentsAllowed.  The corpus contains ZERO, so this is the only
# place the difference gets measured.
add("frag/top-string", '"hello"')
add("frag/top-number", "42")
add("frag/top-negative", "-1.5")
add("frag/top-true", "true")
add("frag/top-false", "false")
add("frag/top-null", "null")
add("frag/top-string-empty", '""')
add("frag/bare-word", "hello", "MALFORMED")
add("frag/true-with-garbage", "truex", "MALFORMED")

# depth: swift-foundation and Darwin's CF parser have historically differed on
# where they stop.  Ladder rather than a single value, so the answer is a
# NUMBER and not a yes/no.
for d in (8, 16, 32, 64, 128, 256, 512, 513, 1024):
    add("depth/array-%d" % d, "[" * d + "1" + "]" * d)
for d in (64, 512, 513):
    add("depth/object-%d" % d, '{"a":' * d + "1" + "}" * d)

# ---- literal casing and near-literals -------------------------------------
add("lit/true-uppercase", '{"v":True}', "MALFORMED")
add("lit/null-uppercase", '{"v":NULL}', "MALFORMED")
add("lit/nil", '{"v":nil}', "MALFORMED")
add("lit/undefined", '{"v":undefined}', "MALFORMED")

# ---- shapes that stress the container machinery ---------------------------
add("shape/array-of-1000-ints", json.dumps(list(range(1000))))
add("shape/object-200-keys",
    json.dumps({("k%03d" % i): i for i in range(200)}, sort_keys=True))
add("shape/heterogeneous-array",
    '[null,true,false,0,-1,1.5,1e3,"s",[],{},[[]],{"a":{}}]')
add("shape/mixed-nesting",
    '{"a":[{"b":[{"c":[1,2,{"d":null}]}]}],"e":{"f":[[],[{}]]}}')


def main():
    out = []
    for i, (label, payload, note) in enumerate(DOCS):
        out.append({
            "id": "syn-%04d" % i,
            "set": "synthetic",
            "kind": "generated",
            "origin": label,
            "note": note,
            "bytes": len(payload),
            "b64": base64.b64encode(payload).decode("ascii"),
        })
    with open(sys.argv[1], "w") as fh:
        json.dump(out, fh, indent=1, sort_keys=True)
    print("wrote %s: %d synthetic docs" % (sys.argv[1], len(out)))
    fams = {}
    for d in out:
        fams[d["origin"].split("/")[0]] = fams.get(d["origin"].split("/")[0], 0) + 1
    for k in sorted(fams):
        print("   %-8s %d" % (k, fams[k]))


if __name__ == "__main__":
    main()
