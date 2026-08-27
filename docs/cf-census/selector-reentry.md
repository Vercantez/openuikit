# Which bridged selectors can re-enter CF, and the rule for checking a new one

Asked for after `-hash`/`-isEqual:` forwarding to `CFHash`/`CFEqual` hung the
process: a 90-second timeout, exit 124, no crash and no output. The question is
which of the harvested selectors have the same property, and the answer turns
out to be smaller and sharper than the question — but it uncovered **three live
crashes that have nothing to do with my addition.**

## The rule, stated so a new selector can be checked against it

> **A selector `-foo` may forward to `CFFoo` if and only if `CFFoo` contains no
> dispatch back to `-foo`.**

That is mechanically checkable, and CF makes it easy because the dispatch is
always an explicit macro. Two kinds exist and **they behave differently**:

```
CF_OBJC_FUNCDISPATCHV(typeID, ...)   TAKES the typeID; compares the object's
                                     _cfisa against THAT typeID's slot
CFTYPE_OBJC_FUNCDISPATCH0/1(...)     TYPE-ID FREE; compares _cfisa against the
                                     slot for the object's OWN typeID
```

**Why lifetime is safe** — `CFRetain` (CFRuntime.c:823) contains **no dispatch
at all**; it asserts and calls `_CFRetain`. So `-retain → CFRetain` cannot
cycle, for a reason visible in CFRetain rather than in `-retain`.

**Why hashing is not** — `CFHash` (CFRuntime.c:1005) contains
`CFTYPE_OBJC_FUNCDISPATCH0(CFHashCode, cf, hash)`. A `-hash` calling `CFHash`
closes the loop. The two methods look identical at the call site; the difference
is entirely on CF's side.

## The typeID-free dispatch sites — all five, and they are the dangerous set

```
CFRuntime.c:772   CFGetTypeID   ->  -_cfTypeID
CFRuntime.c:966   CFEqual       ->  -isEqual:
CFRuntime.c:981   CFEqual       ->  -isEqual:
CFRuntime.c:982   CFEqual       ->  -isEqual:
CFRuntime.c:1005  CFHash        ->  -hash
(CFRuntime.c:1019 _copyDescription is commented out upstream)
```

Three selectors: **`_cfTypeID`, `isEqual:`, `hash`.**

## THE LIVE BUG THIS EXPOSED: constant strings are permanently "foreign"

`_CFTypeIsObjC` is `isa != 0 && isa != __CFISAForTypeID(typeID_of(obj))`. For a
`CFSTR` the isa is `__NSCFConstantString` while CFString's slot holds
`__NSCFString`. **They differ, so every constant string takes the ObjC branch of
every typeID-free dispatch.** `__NSCFConstantString` implements none of the
three, so:

```
CFGetTypeID(CFSTR("x"))
  -> objc[]: -[__NSCFConstantString _cfTypeID]: unrecognized selector
     sent to instance 0x100004008
```

Measured, not predicted. `CFEqual` and `CFHash` on a constant string are the
same crash. **None of this was caused by the `-hash` addition** — that only made
it a hang instead of a crash, by supplying the missing method in a form that
looped.

Real Foundation has the same isa/slot asymmetry and survives it because its
`__NSCFConstantString` implements the full NSString surface. Ours implements
`length`, `characterAtIndex:` and lifetime.

## A false claim in our own test, corrected

`t9_bridge.m` asserted its dictionary lookup "requires CFHash/CFEqual to agree
across two distinct CFSTRs". **It does not.** `CFSTR("a")` evaluated twice
yields the *same pointer* (measured: `0x100004008` both times), so the lookup
short-circuits on identity and never hashes. The test passed for a weaker reason
than its comment claimed — and it cannot be strengthened with a
distinct-but-equal key until the three selectors above exist, because that path
crashes.

**This is the same shape as the retain/release round trip**: an assertion that
holds for a reason other than the one stated, and reads as stronger evidence
than it is.

## Status of the implemented selectors

Every currently-implemented forwarding selector was checked against the rule.
Only `hash` and `isEqual:` were cyclic, and both are removed. The rest forward
to CF functions carrying either no dispatch or a typeID-taking dispatch that
resolves false for a correctly-registered instance — which is exactly the
invariant the isa fix restored, so **the isa fix is what makes the other
forwards safe**, not a property of the selectors themselves.

## What to do, and what not to

The three selectors must be implemented on `__NSCFConstantString` **without
calling back into CF**: `-_cfTypeID` returns CFString's typeID directly,
`-hash` and `-isEqual:` compute over the string's own bytes. Forwarding them is
what caused the hang.

Whether they belong on `__NSCFType` for all twenty classes is a separate
question and should not be assumed — for a correctly-registered instance the
typeID-free check is false, so those classes never receive these messages.
**Constant strings are the exception precisely because their isa cannot match
the slot.**

## Addendum: `CFStringHashCString` is part of a documented runtime contract

Chosen for `-hash` on re-entry-safety and correctness-by-construction grounds —
it takes bytes rather than a receiver, and it is CF's own hash. team-lead points
out it is also **one of the four CF functions libswiftCore looks up by name at
runtime**, which makes it interface rather than workaround.

Verified, and the verification has a discriminator worth keeping:

```
                          undefined-symbol   string
CFStringHashCString              0             1
CFGetTypeID                      0             1
CFStringGetTypeID                0             1
CFStringHashNSString             0             1
CFRelease                        0             0
```

**A `dlsym`'d name appears as a STRING and not as an undefined symbol** — it is
looked up, not linked. All four show that signature. Our CF exports all four
(measured in the built objects), so the contract is satisfied today.

`CFRelease` was a badly chosen control: it appears as *neither*, because
libswiftCore does not reference it at all. The lesson is that
**string-present/symbol-absent is itself the positive discriminator** — a
linked symbol would have shown the opposite pattern, and picking one that shows
neither proves nothing either way. The four agreeing on the signature, with a
name that is genuinely absent showing neither, is the evidence.

## Precondition for the `-userInfo` ownership fix — checked, and it has a trap

t10 pins the leak at `2 → 7 over 5 calls`, exactly +1 per call. The named fix is
autorelease. Before designing anything, is autorelease available?

**The Objective-C machinery is all present** in machorun's libobjc:

```
objc_autoreleasePoolPush      1
objc_autoreleasePoolPop       1
objc_autorelease              1
objc_autoreleaseReturnValue   1
```

**But the obvious CF-level shortcut is a trap.** `CFAutorelease` is defined —
`CFRuntime.c:829` — and it is a **no-op**:

```c
CFTypeRef CFAutorelease(CFTypeRef __attribute__((cf_consumed)) cf) {
    if (NULL == cf) { CRSetCrashLogMessage("*** CFAutorelease() called with NULL ***"); HALT; }
    return cf;
}
```

It returns its argument and does nothing else. corelibs has no pool to drain
into, so it kept the symbol and dropped the behaviour.

**Anyone reaching for the CF-named function would "fix" the leak, see t10 still
green, and have changed nothing** — and t10 asserts the leak, so green is
exactly what a no-op fix produces. That is the failure this file already
documents twice: a call that succeeds and does nothing, indistinguishable from
one that works.

**So the fix must go through `objc_autorelease` (or a real pool), not
`CFAutorelease`**, and t10's assertion must FLIP rather than stay green — a fix
that leaves it passing has done nothing.
