# The `NSMutableArray` stub: a test fixture that will be mistaken for Foundation

**If you arrived here from a runtime warning, this is the answer:** the
`NSMutableArray` in your process is an **empty test fixture** from
foundation-macho's stub library, not Foundation's. Nothing about it works.

## Why it exists and why it cannot be renamed

CoreFoundation references `NSMutableArray` as a **class object**, not through a
cast, and the Objective-C runtime fixes up class references at image load. A
`void *` data stub — which is what the other 239 stubbed symbols get — does not
survive that. It has to be a real class, and it has to have exactly that name.

## Why it is a hazard rather than an inert placeholder

`libswiftCore`'s `_swift_stdlib_connectNSBaseClasses` re-parents six classes at
runtime via `class_setSuperclass`: NSString, NSArray, **NSMutableArray**,
NSDictionary, NSSet, NSEnumerator. It finds them **by name** and has no way to
distinguish a fixture from the real thing.

So the moment libswiftCore is loaded into a process that also has this stub,
**it will re-parent an empty class of ours and believe it has connected
Foundation.** Nothing in either component is wrong; they simply agree on a name.

It is inert today only because libswiftCore is not loaded in the CF test
process. That is a property of the current test, not of the design — the general
form being: **a stub created to satisfy a linker becomes a participant the
moment something looks classes up by name.**

## What was done about it

It announces itself. `+initialize` writes to stderr on first use:

```
*** foundation-macho TEST FIXTURE: NSMutableArray is a STUB ***
*** Not Foundation. See docs/cf-census/nsmutablearray-stub.md ***
```

Verified by control (`/work/t15.m`): sending it `-count` produces the banner
immediately above the runtime's unrecognized-selector abort.

**One honest limitation, measured rather than assumed:** the class also
overrides `-doesNotRecognizeSelector:`, and that override **does not run** — the
runtime's own unrecognized-selector path aborts first. The `+initialize` banner
is what actually does the work. The override is left in place because it costs
nothing and would fire under a runtime that dispatches it, but it should not be
relied on.

## What would make it unnecessary

A real `NSMutableArray`. Until the model layer supplies one, the fixture is the
honest arrangement: **loud and documented beats absent-and-linking-fails, and
beats silent-and-plausible by a much wider margin.**
