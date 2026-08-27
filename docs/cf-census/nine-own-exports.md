# The nine "undefined" symbols that are our own — one root cause, four faces

machorun-isamask was right to refuse to implement these, and right that they are
a build-configuration defect. They are not a libSystem gap. **All four causes
reduce to the same thing: an aliasing or feature mechanism that does not survive
our toolchain, silently.**

The unifying condition: **we are `TARGET_OS_MAC` by target triple and corelibs by
implementation.** corelibs' sources branch on `TARGET_OS_MAC` meaning "Apple's
CoreFoundation is present, so it supplies this." It is not present. We take
Apple's branch without Apple's code.

## 1. Six CF constants — an `#if` we fall outside of, and an attribute Darwin rejects

`CFLocaleKeys.c:136`

```c
// Aliases for other platforms.
#if TARGET_OS_LINUX || TARGET_OS_BSD || TARGET_OS_WIN32 || TARGET_OS_WASI
CF_EXPORT CFStringRef const kCFGregorianCalendar
    __attribute__((alias ("kCFCalendarIdentifierGregorian")));
    ... 99 of these ...
#endif
```

The alias *targets* are defined and present in `CFLocaleKeys.o`; the aliases are
not, because the block is skipped for a Darwin target. **And it cannot simply be
enabled** — measured directly:

```
$ clang -target arm64-apple-macos13.0 ... alias probe
error: aliases are not supported on darwin
```

So this is not one wrong `#if`. It is 99 symbols needing a mechanism that
compiles on Mach-O. **The one that works is an asm `.set`**, already proven in
this tree for `___CFConstantStringClassReference`.

Six show up as undefined only because those are the six CF's *own* link
references. The other 93 are absent too and will surface as consumers use them.

## 2. `_CFThreadSetName` — a feature macro that is simply off

`CFPlatform.c:1818` defines it, guarded by
`#if SWIFT_CORELIBS_FOUNDATION_HAS_THREADS`. Probed: **the macro is not defined
for us**, so `CFPlatform.o` defines zero copies. CF plainly has threads in our
configuration. This is the only one of the four that is a genuine one-flag fix.

## 3. `__CFMachPortClass` — a table entry for a file corelibs does not have

`CFRuntime.c:234`

```c
#if TARGET_OS_MAC
    [_kCFRuntimeIDCFMachPort] = &__CFMachPortClass,
#endif
```

**`CFMachPort.c` does not exist in corelibs at all.** The runtime class table
takes the Darwin branch and references a class nothing defines. The purest form
of the root cause: `TARGET_OS_MAC` used to mean "Apple's CF is here."

Since our CFRunLoop is the epoll backend with no Mach IPC, the entry has no
meaning for us and the right fix is to exclude it, not to invent a class.

## 4. `_dispatch_queue_attr_concurrent` — a LINKER mechanism, and our linker lacks it

`libdispatch/src/init.c:421`

```c
// _dispatch_queue_attr_concurrent is aliased using libdispatch.aliases
// and the -alias_list linker option on Darwin but needs to be done manually
// for other platforms.
#ifndef __APPLE__
```

`xcodeconfig/libdispatch.aliases` really does contain
`__dispatch_queue_attrs __dispatch_queue_attr_concurrent`. We compile with
`__APPLE__` so the manual alias is skipped, and the Darwin path wants a linker
option. Passing it:

```
ld64.lld: warning: Option `-alias_list' is not yet implemented. Stay tuned...
link exit: 0
exports of _dispatch_queue_attr_concurrent: 0
```

**The link succeeded, warned, and produced nothing** — an option that is
accepted and ignored. Caught only by checking the artifact for the symbol
rather than the exit code, which is the same discipline that caught the patch
tool reporting "already patched" while changing nothing.

## The fix, and why it is one fix

Three of the four need **asm `.set` aliases emitted into a compiled object**,
because that is the only aliasing mechanism that survives Mach-O plus ld64.lld:

- `__attribute__((alias))` — rejected by clang on Darwin
- `-alias_list` — accepted and ignored by ld64.lld
- `.set` in inline asm — **works**, proven by the constant-string alias

`_CFThreadSetName` is separate and is a define.

Nothing here should be implemented in libSystem. Defining CF's own constants
outside CF would be a second definition, and today has been an extended lesson
in what a second definition costs.
