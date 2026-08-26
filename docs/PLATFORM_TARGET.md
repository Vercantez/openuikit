# Should the stack target `arm64-apple-ios-simulator` instead of `arm64-apple-macos`?

**Recommendation: no. Keep `arm64-apple-macos`.** The benefit the retarget would
buy has already been delivered by the loader fix, the specific thing it was
hoped to fix is provably unaffected by it, and the cost lands on machorun's
verification methodology, which is the project's most valuable asset.

This is a negative result and it is worth what a positive one would have been:
it saves a migration.

Everything below is measured on binaries and source already on disk. **No build
box was provisioned** — see §6 for why one would not have settled anything the
local evidence did not.

---

## 1. What actually differs

Measured, with "no difference" recorded where that is the truth.

| property | `arm64-apple-macos` | `arm64-apple-ios-simulator` | matters? |
|---|---|---|---|
| architecture | plain arm64 | plain arm64 | **no difference** — neither is arm64e |
| calling convention, struct layout | arm64 Darwin | arm64 Darwin | **no difference** |
| Swift isa mask baked into libswiftCore | narrow `0x00007ffffffffff8` (bits 3..46) | wide `0x007ffffffffffff8` (bits 3..54) | **the entire question** |
| objc4 `FAST_DATA_MASK` / `DEBUG_DATA_MASK` | `#else` branch → `0x00007ffffffffff8` | **same `#else` branch, identical value** | **no difference — see §3** |
| `LC_BUILD_VERSION` platform | 1 (MACOS) | 7 (IOSSIMULATOR) | loader **ignores it** (`src/image.c:317` skips the command) |
| `dyld_get_active_platform()` | machorun hardcodes `1` | would need `7` | one line in `src/objc_notify.c:409` |
| `dyld_program_sdk_at_least()` | always returns 1 | same | no difference — machorun stubs it true |
| Apple ships a runtime | yes (`arm64-macos` is in the full Xcode SDK tbd) | yes | **both are supported configurations** |
| availability versioning | macOS 15.x | iOS 26.x | pervasive but mechanical |
| our SDK `.tbd` targets | `*-macos` | would need `*-ios-simulator` | migration cost |
| differential oracle | run natively on macOS | cannot; needs a simulator | **§5, the real cost** |

A correction to an assumption I nearly shipped: the CommandLineTools macOS SDK
tbd lists only `x86_64-macos, arm64e-macos`, which looks like Apple ships no
plain-arm64 macOS Swift runtime. The **full Xcode** SDK tbd lists `arm64-macos`
as well. Our target is not an unsupported configuration.

## 2. The mask difference is real but I could not confirm its cause from source

Measured fact: Apple's shipped arm64 iOS-simulator `libswiftCore` carries the
wide mask at all 48 isa sites; ours, built for `arm64-apple-macos`, carries the
narrow mask at the same 48 sites.

I could **not** verify the mechanism. The isa mask is not in Swift's shipped
headers — `swift/shims/System.h` and `swift/shims/HeapObject.h` contain the
spare-bits and ObjC-reserved-bits masks but no isa mask, and the macOS and
simulator SDK copies of both are hardlinked-identical. The constant lives in
compiler-internal source that is not shipped. So the platform→mask link is an
**inference from two binaries**, with a version confound (Apple's is the iOS
26.1 runtime, ours is 6.2.4).

I am flagging that rather than asserting it, because asserting an unverified
link is exactly the error that sent the first isa diagnosis toward refcounting.
It does not change the recommendation — §3 and §4 hold regardless of whether
retargeting would flip the mask.

## 3. It would *not* moot the `class_rw_t` heap constraint

This was asked specifically, and the answer is a clean no.
`objc-runtime-new.h:132-138`:

```c
#if   TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
#define DEBUG_DATA_MASK         0x0000007ffffffff8UL
#else
#define DEBUG_DATA_MASK         0x00007ffffffffff8UL   // 2^47
#endif
```

**A simulator target takes the same `#else` branch macOS does.** The data mask,
and therefore the 2^47 ceiling on `class_rw_t`, is byte-identical either way.
Retargeting changes the isa mask and leaves the data mask exactly where it is.

That matters beyond the narrow question: the `class_rw_t` truncation is the
harder of the two bugs — it is heap-allocated, it hides behind libswiftCore's
64 KiB static `InitialAllocationPool` so small programs falsely pass, and it
surfaces only under a real workload. Retargeting would have silenced the *isa*
bug and left the *data* bug live, i.e. removed the loud symptom and kept the
quiet one. On this evidence retargeting early would have made the project harder
to debug, not easier.

## 4. The benefit is already delivered

With machorun placing images **and** the heap below 2^47 (`fix/map-below-isa-mask`
plus `mr_constrain_heap()`), a 47-bit mask is *correct*, not merely tolerated. A
wider mask only helps for addresses above 2^47, and those no longer occur — by
construction and with a startup assertion that dies loudly if they ever do.

So retargeting buys nothing on the mask that the loader has not already bought,
and it buys it for **Apple's shipped runtime too**, which retargeting our own
binaries could never do.

Both walls we hit were caused by addresses above 2^47 — a loader placement
property — not by our build target. Fixing them at the target would have been
fixing a symptom in our binaries while leaving the environment wrong for
everyone else's.

## 5. What it would cost, and the part that actually hurts

Mechanical: rebuild `libswiftCore`; re-tag every `.tbd` in machorun's SDK;
rebuild objc4, quartz and libSystem for the new platform; flip
`dyld_get_active_platform()` to 7. Days, not weeks, and all tractable.

The part that hurts is **verification**. machorun's differential methodology
runs the same bytes natively on macOS and compares stdout, stderr and exit
status — 13/14 byte-identical, with oracle guards that refuse to grade unless
the baseline provenance says Darwin. An `arm64-apple-ios-simulator` binary
cannot be run that way; it needs a simulator host. That is not a detail, it is
the mechanism by which this project knows it is correct. Trading it for a mask
we no longer need is a bad trade.

Second risk: it would move the stack off the only configuration proven end to
end. `boxes_basic` currently renders pixel-identical to Apple's UIKit in three
independent configurations. Retargeting invalidates all three.

## 6. Why no box

A box would have answered one question: does `-target arm64-apple-ios-simulator`
actually flip our libswiftCore's mask (§2's unverified link)? That question is
**moot for the decision** — §3 and §4 are independent of it, and both point the
same way. Provisioning to prove a negative I had already established locally
would have been the exact habit `BUILD_LOG.md` §10 warns about. If the team
wants to overrule this recommendation, the rebuild is the first thing to do and
it does need a box.

## 7. What would change my mind

One trigger, and it is concrete: **if we start loading Apple's shipped
iOS-simulator frameworks as guests** — real `UIKit.framework`,
`Foundation.framework` — rather than running our own reimplementations. At that
point platform coherence starts to matter for availability gating and objc
behaviour flags, and a macOS-platform host loading iOS-platform guests is a
mismatch worth removing. Today we load our own code, and the platform byte is
inert (`src/image.c` skips it).

## 8. An unrelated simplification this surfaced

Now that the loader guarantees everything is below 2^47, machorun could likely
**revert the widening in `patches-macho/0001` entirely** and use Apple's stock
`ISA_MASK` and `FAST_DATA_MASK`. That would make our objc4 bit-compatible with
Apple's shipped runtime on both masks and shrink the patch set — the opposite
direction from retargeting, and earned by the same loader fix. Worth testing
separately; it belongs to machorun, not here.
