# ABI — where Darwin/arm64 and Linux/aarch64 disagree

Everything on this page was **measured on 2026-08-25** on the machines this
project actually uses: macOS 26.5.2 with Apple clang 17 on Apple silicon, and
Ubuntu 24.04 with clang-18 in a native arm64 container. Nothing here is quoted
from a specification. Where a claim has a reproducer, the command is given.

The reason this document exists: our libSystem is compiled **for Darwin** and
calls **into glibc**. Every call therefore crosses an ABI boundary in the middle
of a process. Most of that boundary is identical and costs nothing. The parts
that are not identical are listed here, and each one is covered by a fixture
that would fail without it — `scripts/abi_naive_probe.sh` disables the
translations one at a time and shows exactly how the output moves.

---

## Summary

| what | Darwin/arm64 | Linux/aarch64 | bites? |
|---|---|---|---|
| variadic arguments | all on the stack, 8 bytes each | x1-x7 / v0-v7 then stack | **yes, fatally** |
| `sizeof(va_list)` | 8 (a bare `char *`) | 32 (a struct) | **yes** |
| `long double` | 8 bytes (an alias for `double`) | 16 bytes (IEEE binary128) | **yes** |
| stack slots, non-variadic | packed to natural size | padded to 8 bytes | only past 8 args |
| struct return | x0 / x0-x1 / x8 indirect / HFA in s0-s3 | identical | no |
| struct arguments | identical | identical | no |
| `errno` values | 54 of 87 shared names differ | — | **yes** |
| `O_*` flags | 10 of 13 differ | — | **yes** |
| `struct stat` | 144 bytes | 128 bytes, different offsets | **yes** |
| `CLOCK_MONOTONIC` | 6 | 1 | **yes** |
| `struct timespec` / `timeval` / `tm` | 16 / 16 / 56 bytes | identical | no |
| `S_IFMT` and permission bits | identical | identical | no |
| `SEEK_SET/CUR/END` | 0/1/2 | identical | no |
| `PROT_READ/WRITE/EXEC` | 1/2/4 | identical | no |
| page size | 16 KiB | 4 or 16 KiB | **yes, latently** |

---

## 1. The variadic ABI — the one that kills

Apple's arm64 calling convention departs from AAPCS64 for variadic calls, and
this is not a corner case: it is `printf`.

**Caller side.** `vf("x", 1, 2.5, 3, 4.5, 5L, "s", 7, 8, 9)` compiled both ways:

```
$ clang -target arm64-apple-macos12 -O1 -S va_probe.c      # macOS
        stp     x9, x8, [sp]            <- 1, 2.5
        stp     x9, x8, [sp, #16]       <- 3, 4.5
        stp     x9, x8, [sp, #32]       <- 5, "s"
        stp     x9, x8, [sp, #48]       <- 7, 8
        str     x8, [sp, #64]           <- 9
        adrp    x0, l_.str              <- ONLY the format is in a register
        bl      _vf
```

```
$ clang -O1 -S va_probe.c                                   # Linux container
        fmov    d0, #2.50000000         <- doubles in the FP file
        fmov    d1, #4.50000000
        mov     w1, #1                  <- integers in x1..x7
        mov     w2, #3
        mov     w3, #5
        adrp    x4, .L.str.1
        mov     w5, #7
        mov     w6, #8
        mov     w7, #9
        b       vf
```

Darwin puts **every** variadic argument on the stack, one 8-byte slot each, in
declaration order — integers and doubles in the same run. Linux splits them
across two register files and only spills the ninth onward.

**Callee side.** `sizeof(va_list)` is **8** on Darwin (the callee just walks the
incoming stack: `add x8, x29, #16` then `ldr ..., [x8], #8`) and **32** on
Linux, where the prologue spills eight GPRs and eight Q registers (128 bytes)
into a register save area before `va_arg` can index it.

### What a naive forwarder does

A libSystem whose `printf` hands its `va_list` to glibc's `vprintf`:

```
$ scripts/abi_naive_probe.sh varargs
=== varargs -- running 03_printf
    exit: 139 (macOS: 0)
    stderr:
      machorun: guest died with SIGSEGV at pc 0xffffbd459154 (fault address 0x4d2)
```

`0x4d2` is 1234 — the first argument of `printf("int=%d\n", 1234)`. glibc read
the guest's integer as the `stack` field of a `struct __va_list` and
dereferenced it.

### The rule this forces

**A variadic function is never a forwarder.** The whole `printf` family is
implemented in `darwin/src/libsystem.c` over the Darwin `va_list`, and only
finished bytes go to glibc.

### The one legal crossing

Float formatting is delegated to glibc's `snprintf`, declared **non-variadically**
with the exact shape we call it with:

```c
extern int glibc_snprintf_d(char *, size_t, const char *, double) GLIBCSYM(snprintf);
```

This is safe, and the reason is worth stating precisely: an AAPCS64 variadic
callee spills x0-x7 and v0-v7 to its register save area on entry, so an ordinary
non-variadic call places `buf`, `cap`, `spec`, `value` in exactly the registers
that its `va_arg` will read them back from. Correct rounding of doubles is not
something to reimplement for a fixture.

### `long double`

`sizeof(long double)` is **8** on Darwin — it is literally `double` — and **16**
on Linux/aarch64. So `%Lf` consumes one slot in a Darwin list and two in a Linux
one. This is a second, independent reason the printf family cannot be forwarded,
and it would still bite even if the `va_list` shapes agreed. Covered by
`11_varargs` (`ldbl=2.500 2.500000e+00 sizeof=8`).

---

## 2. Struct return and struct arguments — measured, and *identical*

Worth checking precisely because it costs nothing when it turns out to agree.
Returning structs of 4, 8, 12, 16 and 24 bytes, plus a four-float HFA, compiled
both ways produces the same instruction sequences:

| returned | both ABIs |
|---|---|
| 4 bytes | `w0` |
| 8 bytes | `x0` |
| 12 bytes | `x0` + `w1` |
| 16 bytes | `x0`, `x1` |
| 24 bytes | caller-allocated buffer, address in `x8` |
| `struct { float a,b,c,d; }` | `s0`-`s3` (HFA) |

Struct **arguments** agree too, including passing a 24-byte struct by reference
in a GPR. So `div_t`, `struct timespec` and friends cross the boundary with no
translation, and we write no code for them.

## 3. Stack argument packing — differs, but out of reach

For a **non-variadic** call whose arguments overflow x0-x7, the two ABIs lay the
stack out differently. Twelve arguments of `char`/`short`:

```
Darwin:  strb w10, [sp]      strh w9, [sp, #2]   strb w8, [sp, #4]   strh w8, [sp, #6]
Linux:   strb w10, [sp]      strh w8, [sp, #8]   strb w9, [sp, #16]  strh w8, [sp, #24]
```

Darwin packs each stack argument to its natural size; AAPCS64 gives every one a
full 8-byte slot. This is real, but it cannot bite here: it needs a call with
more than eight arguments *and* small integer types crossing the libSystem
boundary, and no function in our surface has more than six. Recorded so that the
next person adding a wide-signature entry point knows to check.

---

## 4. `errno` — 54 of 87 names differ

`scripts/gen_errno_table.sh` compiles the intersection of the two `errno.h`
files on both platforms and prints the values. Of the 87 names that exist on
both systems, **54 have different values**. The dangerous ones are not the
merely-different, they are the **swapped**:

| name | Darwin | Linux |
|---|---|---|
| `EAGAIN` / `EWOULDBLOCK` | 35 | 11 |
| `EDEADLK` | 11 | 35 |
| `ENOTEMPTY` | 66 | 39 |
| `ELOOP` | 62 | 40 |
| `ENAMETOOLONG` | 63 | 36 |
| `ENOSYS` | 78 | 38 |
| `ETIMEDOUT` | 60 | 110 |
| `ECONNREFUSED` | 61 | 111 |
| `EILSEQ` | 92 | 84 |
| `EOVERFLOW` | 84 | 75 |

`EAGAIN` and `EDEADLK` are exactly each other's numbers. A guest that forwards
raw does not get a wrong-looking number, it gets a *plausible* one.

Those constants are compiled into the guest: `if (errno == EAGAIN)` in guest code
is a comparison against the literal 35 and nothing else.

### The protocol

Darwin spells `errno` as `(*__error())`, so **every read and every write** in the
guest is a call into libSystem. We keep the guest's errno in our own per-thread
slot and bracket every erroring call:

```
mr_errno_in()     guest slot -> glibc errno     (before)
<the glibc call>
mr_errno_out()    glibc errno -> guest slot     (after)
```

Both halves are needed. With only the second, the classic

```c
errno = 0;
v = strtol(s, &end, 10);
if (errno == ERANGE) ...
```

breaks: the guest's `errno = 0` lands in *our* slot, glibc never sees it, and a
stale glibc errno is translated back on top of the guest's clear.
`13_errno` covers both directions (`errno after success=0`, `guest-set errno
persists=yes`).

A Linux errno with no Darwin twin is reported as its **negative**, so it is
visibly not a valid Darwin errno rather than silently aliasing one.

### `strerror`

The text is Apple's, recorded from macOS by the generator, not glibc's version
of it. Translating the number and asking glibc would be a second guess: the two
libcs do not agree on every message.

### Naive forwarding, measured

```
$ scripts/abi_naive_probe.sh errno
      < rmdir nonempty rc=-1 errno=66 ENOTEMPTY=66 match=yes    (macOS)
      > rmdir nonempty rc=-1 errno=39 ENOTEMPTY=66 match=no     (naive)
    stderr:
      perror says: Undefined error: 0
```

---

## 5. `open()` flags — 10 of 13 differ, and they collide

| flag | Darwin | Linux |
|---|---|---|
| `O_RDONLY/WRONLY/RDWR` | 0 / 1 / 2 | same |
| `O_NONBLOCK` | 0x0004 | 0x0800 |
| `O_APPEND` | 0x0008 | 0x0400 |
| `O_SYNC` | 0x0080 | 0x101000 |
| `O_NOFOLLOW` | 0x0100 | 0x8000 |
| `O_CREAT` | 0x0200 | 0x0040 |
| `O_TRUNC` | 0x0400 | 0x0200 |
| `O_EXCL` | 0x0800 | 0x0080 |
| `O_NOCTTY` | 0x20000 | 0x0100 |
| `O_DIRECTORY` | 0x100000 | 0x4000 |
| `O_CLOEXEC` | 0x1000000 | 0x80000 |

Look at the collision: **Darwin's `O_CREAT` (0x0200) is Linux's `O_TRUNC`**, and
Darwin's `O_TRUNC` (0x0400) is Linux's `O_APPEND`. Forwarding the flag word does
not produce a different error message, it performs a **different operation** —
a create becomes a truncate-if-exists, which fails `ENOENT` on a new file and
destroys an old one:

```
$ scripts/abi_naive_probe.sh flags
    exit: 1 (macOS: 0)
    stderr:
      open: No such file or directory
```

`O_SHLOCK`, `O_EXLOCK`, `O_EVTONLY` and `O_SYMLINK` have no Linux equivalent.
They abort rather than being dropped, because dropping them silently changes the
semantics the caller asked for.

---

## 6. `struct stat` — 144 bytes against 128

Measured with `offsetof` on both platforms:

| field | Darwin offset / size | Linux offset / size |
|---|---|---|
| `st_dev` | 0 / 4 | 0 / 8 |
| `st_ino` | 8 / 8 | 8 / 8 |
| `st_mode` | **4 / 2** | **16 / 4** |
| `st_nlink` | **6 / 2** | **20 / 4** |
| `st_uid` | 16 | 24 |
| `st_gid` | 20 | 28 |
| `st_rdev` | 24 / 4 | 32 / 8 |
| a/m/c times | 32, 48, 64 | 72, 88, 104 |
| `st_birthtimespec` | 80 | *absent* |
| `st_size` | **96** | **48** |
| `st_blocks` | 104 | 64 |
| `st_blksize` | 112 | 56 |
| `sizeof` | **144** | **128** |

`S_IFMT` and the permission bits agree, so only the *placement* and *width* of
`st_mode` need work — but every field after `st_ino` moves. Copying the bytes
across gives a 12-byte file a `st_size` of 471711007 and `S_ISREG` of false:

```
$ scripts/abi_naive_probe.sh stat
      < stat rc=0 size=12 isreg=yes isdir=no perm=644 nlink=1        (macOS)
      > stat rc=0 size=471711007 isreg=no isdir=no perm=000 nlink=0  (naive)
```

Linux has no birth time in this struct (`statx` has it), so `st_birthtimespec`
is filled from `st_ctim` rather than left as a zero that would date every file
to 1970.

`struct timespec`, `struct timeval` and `struct tm` are byte-identical on the
two platforms (16, 16 and 56 bytes, same field offsets including `tm_gmtoff` and
`tm_zone`), so they are passed straight through.

---

## 7. Clocks, pages and Mach units

**`CLOCK_MONOTONIC` is 6 on Darwin and 1 on Linux.** Passing the guest's id
through lands on Linux's `CLOCK_REALTIME_ALARM`, which needs a capability and
fails with `EPERM`. `darwin/src/posix.c` translates the whole `CLOCK_*` set.

**Page size.** Darwin/arm64 is always 16 KiB. Linux/arm64 may be 4 KiB. A guest
compiled for macOS is entitled to assume 16 KiB, so `vm_allocate` over-maps by
one Darwin page and trims, and `getpagesize()` / `vm_page_size` report 16384
regardless of the host. This is latent rather than currently biting — but it is
the kind of difference that surfaces ten thousand lines later, so it is paid for
up front. `12_mach` asserts `(addr & 0x3fff) == 0`.

**`mach_absolute_time` units.** On Apple silicon the real counter is 24 MHz and
`mach_timebase_info` reports `numer/denom = 125/3`. Ours returns nanoseconds
directly and reports `1/1`. Any correct program multiplies by `numer/denom`
before believing a duration, so the pair is consistent; a program that assumes
the *ratio* is 125/3 without asking was already wrong on Intel Macs.

**`VM_PROT_*` and `PROT_*`** agree (READ 1, WRITE 2, EXECUTE 4), and
`MAP_PRIVATE`/`MAP_FIXED` agree; only `MAP_ANON` differs (0x1000 Darwin, 0x20
Linux) and is translated in `mmap`.

---

## Reproducing all of this

```sh
scripts/gen_errno_table.sh      # re-takes the errno + strerror measurement,
                                # regenerates darwin/src/errno_table.h
scripts/abi_naive_probe.sh      # disables each translation in turn and shows
                                # how far the output moves from the oracle
scripts/difftest.sh 11_varargs 12_mach 13_errno
```

If a variant in `abi_naive_probe.sh` ever reports *"IDENTICAL to macOS — this
translation is not load-bearing"*, delete the translation. Code that no test can
distinguish from its absence is not doing anything.
