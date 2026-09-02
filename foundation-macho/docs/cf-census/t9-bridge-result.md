# Does CoreFoundation WORK? Mostly yes — and the one failure is a real bug in my own adjudication

`tests/t9_bridge.m`, the first time any of this code has executed.

## What works

```
CFStringCreateWithCString -> 0x100138be480
  ok   CFString created
     isa -> __NSCFString
  ok   isa is __NSCFString
  ok   CFGetTypeID is CFString
     CFStringGetLength -> 12
  ok   CFStringGetLength == 12
  ok   CFStringGetCharacterAtIndex
     [str length] -> 12
  ok   -length through the bridge          objc_msgSend -> __NSCFString -> CFStringGetLength
  ok   -characterAtIndex: through bridge
CFSTR("literal") -> 0x100004048
     isa -> __NSCFConstantString
  ok   CFSTR isa is __NSCFConstantString
  ok   CFSTR length == 7
  ok   CFSTR -length through bridge
CFArrayCreate -> 0x100138be740
  ok   CFArray created / GetCount / GetValueAtIndex
     isa -> __NSCFArray
```

**The toll-free bridge executes.** An Objective-C message to a CF-created string
dispatches through `objc_msgSend` into `__NSCFString` and back into
`CFStringGetLength`. That is the entire point of the 151-selector surface and it
had never run. **`CFSTR` literals dereference correctly** — item (4) is now
validated at runtime, not merely at link, and the
`__CFConstantStringClassReferencePtr` NULL bug would have surfaced exactly here.

## What fails: every CFDictionary, CFSet and CFBag

```
CFDictionaryCreate -> 0x10022bce7a0
  ok   CFDictionary created
     isa -> (null) (raw 0x0)
     CFGetTypeID(dict) = 18   CFDictionaryGetTypeID() = 18
  FAIL dict isa is __NSCFDictionary
SIGSEGV in objc_msgSend, fault address 0x10
```

**The mechanism, measured rather than reasoned:**

1. `CFDictionaryCreate` returns a `CFBasicHash`. `CFBasicHash.c:1592` allocates
   it with `_CFRuntimeCreateInstance(allocator, CFBasicHashGetTypeID(), ...)` —
   **typeID 3**.
2. `_CFRuntimeCreateInstance` initialises `_cfisa` from **slot 3**.
   `_kCFRuntimeIDCFBasicHash` is `NOT_BRIDGED`, so slot 3 is empty and
   **`_cfisa = 0`**.
3. The object nevertheless reports typeID **18** — confirmed at runtime,
   `CFGetTypeID(dict) == CFDictionaryGetTypeID() == 18`. My first hypothesis was
   a typeID mismatch and **that was wrong**; the typeID is correct.
4. `CFDictionaryGetCount` dispatches with `CF_IS_OBJC(_kCFRuntimeIDCFDictionary,
   hc)` — slot **18**, which registration filled with `__NSCFDictionary`.
5. `0 != __NSCFDictionary` → **true** → CF sends `-count` to an object whose isa
   is 0 → `objc_msgSend` reads the class at offset 0x10 → SIGSEGV.

**This is t8's case 3 happening for real.** That test asserts that a native
object with `_cfisa == 0` is misreported as foreign; here it is, in production
code, on the most common collection type there is.

## The adjudication line that caused it

`docs/cf-registration.tsv:37`

```
_kCFRuntimeIDCFBasicHash  NOT_BRIDGED  internal storage for CFDictionary/CFSet/CFBag; never handed out
```

**"never handed out" is false.** The CFBasicHash instance *is* the
CFDictionary — `CFDictionaryCreate` returns it directly. The verdict
`NOT_BRIDGED` is defensible (there is no `__NSCFBasicHash` class to bridge to),
but the reason I wrote is wrong, and **the wrong reason is what made the verdict
look safe.** An adjudication carries a claim as well as a verdict, and only the
verdict was ever checked.

Registering 18, 20 and 21 is therefore inert for the object the caller actually
receives: instances carry slot 3's isa and CF dispatches on 18's.

## Why the guard did not catch it

`check_registration.py` reported **8 unresolvable dispatch sites** — CFBag.c:135,
168; CFDictionary.c:164, 187; CFSet.c:150, 173; CFRuntime.c:296, 697 — as "first
argument is a local variable, this tool cannot attribute". **Every collection
type in the failure is in that list.** The guard was pointing straight at this
and reported it as a limitation rather than a finding, and I read it as noise
three separate times.

## Not caused by the remaining fictions

Neither `pthread_atfork` (no-op) nor `_NSGetExecutablePath` (returns the loader
path) is on any path here. Nothing in this test touches bundles or forks. The
failure is CF's own dispatch logic against our registration table.

## What it does not yet say

The fix is not obvious and should not be guessed. Options are (a) give slot 3 the
same class as 18/20/21 so the isa matches whatever CF dispatches on, (b) have CF
set `_cfisa` when a CFBasicHash is vended as a collection, or (c) leave 18/20/21
unregistered so both sides read 0 and agree — which is self-consistent and
disables bridging for collections. **(c) is what the code did before
registration, and it is why nothing crashed before.** Needs a decision, not a
patch.
