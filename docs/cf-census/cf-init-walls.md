# What `__CFInitialize` reaches for, in order, after the sysctl MIBs

Pre-measured rather than discovered serially. These calls are **unreachable
until the one before them is answered**, so no static analysis produces this
list — it is exactly the lower-bound situation that made "ICU 1" become "ICU
12". Finding them one at a time would have cost a round trip to machorun per
wall.

Method: `tests/probe_sysctl.c` answers each wall with the least fiction that
lets CF proceed, and every other symbol is an abort-on-call stub that prints its
own name. Nothing silently passes. All of it is in our tree; none of it ships.

**Result: `__CFInitialize` completes and `T8 PASS`.** There are five walls, and
two of them carry traps that would have been expensive to find later.

## The five, in the order CF hits them

### 1. `sysctl`, five MIBs — machorun, committed on `fix/cf-sysctl-mibs`
Already reported. `{CTL_KERN, KERN_PROC, KERN_PROC_PID}` is the blocker; the
other four are scalars.

### 2. `pthread_getugid_np` — trivial, and NOT fiction
Darwin-only SPI, part of the same "is this process privileged" question as
`_CFGetSVUID`. Returns the thread's effective uid/gid. Linux has no per-thread
ugid override, so the correct implementation *is* `geteuid`/`getegid` — the
probe's version can be taken verbatim.

### 3. `__strlcat_chk` / `__strlcpy_chk` — trivial, and NOT fiction
Apple's `_FORTIFY_SOURCE` variants; the compiler rewrites `strlcat`/`strlcpy`
into these when the destination size is known. Real implementations, in the
probe, takeable almost verbatim.

**One contract detail worth not getting wrong:** both return the length they
*tried* to create, not the length written, so callers detect truncation by
comparing against the buffer size. Returning the written length turns a
detectable truncation into a silent one.

### 4. `pthread_atfork` — **CANNOT BE FORWARDED BY dlsym**
This is the first of the two real findings. The obvious treatment is a plain
forward — three function pointers, no struct, no constant, identical ABI. It
fails at *runtime*:

```
machorun: undefined symbol '_glibc_pthread_atfork'
  looked in: every loaded image (flat lookup)
```

**glibc does not export `pthread_atfork` as a dynamic symbol.** It lives in
`libc_nonshared.a` and is implemented on top of `__register_atfork`, so there is
nothing for `dlsym` to find. A libSystem implementation must call
`__register_atfork(prepare, parent, child, __dso_handle)` instead — the same
shape as `futex`, where the door had to be built rather than forwarded.

Note this is a *third* category beyond the ones already catalogued: not "same
name, different ABI", but **same name, no dynamic symbol at all**. A census that
checks glibc's man pages, or even its headers, finds `pthread_atfork` and
concludes it is forwardable.

The probe treats it as a no-op, and that **is** fiction, recorded as such: atfork
handlers only matter across `fork()`, which this walk never does.

### 5. `_NSGetExecutablePath` — **must return the GUEST path**
The second real finding, and the more dangerous one.

The obvious Linux implementation is `readlink("/proc/self/exe")`. **Under
machorun that returns the loader, not the guest.** The process genuinely *is*
machorun; the Mach-O is something it mapped. CF uses this call to locate the
main bundle, so a `/proc/self/exe` implementation would look entirely correct,
return a real and existing path, and point CF at the wrong file — with every
bundle-relative resource lookup then failing somewhere far away from the cause.

A faithful implementation has to come from the loader's own knowledge of which
guest image it loaded. The probe uses `/proc/self/exe` because it only needs to
get past the call.

## What this does and does not establish

**Does:** `__CFInitialize` has exactly five walls after the MIBs, they are all
small, and CF then initialises completely — `T8 PASS`, with the control showing
`_cfisa -> __NSCFString`, so registration demonstrably happened rather than the
test passing against an empty table.

**Does not:** prove CF is correct with *real* implementations behind those five.
Two are fiction (`pthread_atfork` no-op, `_NSGetExecutablePath` returning the
loader path), and item (3) should be re-run once machorun's versions land. The
CF_IS_OBJC logic itself does not depend on any of them, which is why the result
is meaningful now.
