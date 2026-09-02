# `CFBase.c:109` — which branch does CFAllocator want?

Scoping only, per instruction: **establish which of the two the code wants
before writing anything.** The answer is unambiguous.

## The two branches

```
#if TARGET_OS_MAC     line 109 .. 254   146 lines   <- largest single gate in CF
#else                 line 255 .. 271    17 lines
#endif                line 272
```

**The portable branch is complete for allocation.** All 17 lines:

```c
static void *__CFAllocatorSystemAllocate(CFIndex size, CFOptionFlags hint, void *info) {
    if (hint == _CFAllocatorHintZeroWhenAllocating) return calloc(1, size);
    else                                            return malloc(size);
}
static void *__CFAllocatorSystemReallocate(void *ptr, CFIndex newsize, ...) { return realloc(ptr, newsize); }
static void  __CFAllocatorSystemDeallocate(void *ptr, void *info)            { free(ptr); }
```

**Apple's 146 lines implement the same three functions plus a full
`malloc_zone_t` introspection vtable** — `__CFAllocatorZoneIntrospectTrue`,
`__CFAllocatorZoneIntrospectNoOp`, `__CFAllocatorCustom{Malloc,Calloc,Realloc,
Free,Size,GoodSize}`, `__CFAllocatorNull*`, and `malloc_default_zone`.

**That vtable is heap-TOOLING visibility, not allocation semantics.** It exists
so a CFAllocator appears as a malloc zone to Darwin's `malloc_zone_statistics`,
`leaks` and `heap`. **On Linux there are no such tools to be visible to**, so
the entire difference between the branches buys nothing here.

## Answer: the portable branch, and the cost is one line

The zone symbols do escape the block — 10 references after line 254 — which
looked at first like the objection to adopting the portable path. **Depth-tracked,
nine of the ten are themselves inside `TARGET_OS_MAC` gates** (lines 306, 315,
335, 344, 357, 366 at depth 1; 543, 552 at depth 2), so they disappear together
with the branch. Self-consistent.

**Exactly one is ungated**, `CFAllocatorGetContext` at line 747:

```c
context->info = (allocator->_context.info == &__MallocDefaultZoneInfoPlaceholder)
              ? (void *)malloc_default_zone() : allocator->_context.info;
```

One ternary, referencing both zone-branch names. It needs a guard; everything
else follows.

**This is also why grep would have given the wrong answer.** "Ten references
escape the block" reads as a reason not to touch it. Tracking depth turns it
into "nine are gated, one is not", which is the difference between a port and a
one-line patch.

## Not urgent, and that is measured rather than assumed

`ffe6b0a` established the zone path is **unreached** — the stubs are loud
(`t12_stub_control.m` proves `malloc_zone_memalign` aborts by name) and T9/T10
pass without any allocator stub firing. So this is cleanup of a latent branch,
not a fix for a live failure.

`malloc_zone_memalign` sat on CF's undefined list for hours with no attribution
until the `TARGET_OS_MAC` sweep gave it one. It is a symptom of this gate and of
nothing else.

## What we would lose — enumerated, because "cheaper" is not "equivalent"

Apple had a reason for the zone path. Measured, here is the whole of it:

**1. Visibility to Darwin's heap tools.** A CFAllocator registered as a
`malloc_zone_t` is enumerable by `malloc_zone_statistics`, `leaks` and `heap`.
That is the entire purpose of the `__CFAllocatorZoneIntrospect*`,
`__CFAllocatorCustom{Size,GoodSize}` and `__CFAllocatorNull*` families. **On
Linux there is nothing to be visible to**, so this is lost in name only.

**2. A debug-only poison-on-free.** `CFBase.c:248-250`, inside `#if
defined(DEBUG)`:

```c
size_t size = malloc_size(ptr);
if (size) memset(ptr, 0xCC, size);
```

Genuinely useful — it turns some use-after-free into an obvious pattern — and
genuinely lost, since the portable branch calls `free` and returns. **Worth
re-adding deliberately if we want it**, over `malloc_usable_size`, rather than
carrying 146 lines to keep it. Not a reason to keep the zone path.

**3. Nothing else. In particular, NOT aligned allocation.** `malloc_zone_memalign`
was on CF's undefined list and looks like a real capability, which is what made
this worth checking rather than assuming. `CFBase.c:554`:

```c
memory->memalign = NULL;
```

**Apple's own branch explicitly declines to provide it.** The symbol is
referenced by the zone struct's shape, not by anything CF calls through. So the
portable branch loses no allocation capability whatsoever.

That third point is the one I would have got wrong by reasoning from the symbol
name. `malloc_zone_memalign` appearing on an undefined-symbol list reads as
"CF needs aligned allocation"; the code says the slot is nulled. **An undefined
symbol tells you what was referenced, not what was used.**
