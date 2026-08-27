# What actually kind-checks or Swift-bridges a CF object

Measured 2026-08-27. **Answer: almost nothing, and the one real site is
unreachable today.** Recorded with a date because the value of this result is
that it will change.

## The divergence being assessed

Real `__NSCFString` is a subclass of `NSString`. Ours descends from
`__NSCFType` → `NSObject`. The bridged classes are **siblings** of the six
Foundation clusters, not descendants — which is why inserting `__NSCFType` did
not collide with `connectNSBaseClasses`, and is also why a superclass chain
answers questions differently here than on Darwin.

## CoreFoundation: one kind-check, six respondsToSelector:

```
CFArray.c:968     isKindOfClass:[NSMutableArray class]     <- the only kind-check
CFStream.c:1326,1351,1552,1567,1643,1658   respondsToSelector:  (stream delegates)
```

**The one that matters, `CFArraySortValues`:**

```c
if (CF_IS_OBJC(_kCFRuntimeIDCFArray, array)) {
    result   = CF_OBJC_CALLV((NSMutableArray *)array, isKindOfClass:[NSMutableArray class]);
    immutable = !result;
}
```

Our `__NSCFArray` is not a descendant of `NSMutableArray`, so it would answer
**NO**, CF would set `immutable = true`, and **a mutable array would silently
refuse to sort.** No error, no crash — the operation just does not happen.

**It is unreachable today**, for the same reason the whole forwarding surface is
sound: a CF-created array has `_cfisa` equal to its slot, so
`CF_IS_OBJC` is **false** and this branch is never entered. Control flow reaches
`__CFArrayGetType` instead, which is correct. The branch only opens for an array
whose isa does *not* match the slot — a genuinely foreign ObjC array, which
nothing in this stack produces.

**A second reason it would be wrong if it did run:** `[NSMutableArray class]`
resolves to **our empty test fixture** (see `nsmutablearray-stub.md`), so the
comparison would be against a class that is not Foundation's either.

## libswiftCore

`isKindOfClass:`, `respondsToSelector:` and `isMemberOfClass:` all appear in the
binary. That is expected — it is a Foundation-aware runtime — but **nothing
reaches our objects yet, because libswiftCore is not loaded in any process that
carries them.** When it is, `connectNSBaseClasses` runs first, and the
`NSMutableArray` fixture question arrives before this one does.

## The corpus

Not measured here — `~/swift-macho-linux/full/census` belongs to another scope
and the question ("does app code kind-check a CF object?") is theirs to answer.
Flagged rather than guessed.

## Conclusion, and what would change it

**Nothing performs a kind-check or Swift bridge on a CF object today.** The
divergence is real, its first consequence is identified and located, and it is
gated behind exactly the invariant the isa fix restored.

It becomes live when any of: a foreign ObjC array reaches `CFArraySortValues`;
libswiftCore is loaded alongside these classes; or the bridged classes are
re-parented under the Foundation clusters to match Darwin — which is also the
condition that makes `t11_hierarchy.m` fail. **All three are events someone
performs deliberately, not drift**, which is the useful part: this will not
surprise anyone who reads this file first.
