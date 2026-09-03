# libCFTest stub expectation

Committed files:

- `cftest-stub-func-active.txt` (214 names)
- `cftest-stub-data.txt` (2 names: `OBJC_CLASS_$_NSMutableArray`, `kCFRunLoopDefaultMode`)

`build_cftest_harness.sh` still *derives* the stub set every run (a cached
list of what is missing is a claim with no version in it). After derivation it
compares against this pin and prints `CANNOT_CFTEST_STUBS extra=<names>
missing=<names>` rather than linking a library whose loud stubs hide a missing
object. A 143-name stub set is a CANNOT, not a build.

Measured against recipe `cfobjc.1`, `docs/cf-census/cfobjc-pass.txt` (80 TUs,
`pass-79.txt` + `CFUtilities`), ICU headers present, objects linked with
`probe_sysctl.o` + `src/nscf/*.o` + `sysroot_fe4` `libSystem.B` / `libobjc.A`.
`libCFTest relinked (216 stubbed)` = 214 func + 2 data. `CFStringCreateWithBytes`
is **not** in the set: it comes from `CFString.o`.

## Why each survivor is legitimately absent

| Count | Prefix / names | Why it is not in the objects |
| ---: | --- | --- |
| 21 | `CFRunLoop*`, `__CFRunLoop*` | `CFRunLoop.c` FAIL: `patch_cf_runloop.py` selects the epoll backend; Darwin sysroots have no `sys/epoll.h`. Named in `cfobjc-fail.txt`. |
| 1 | `__CFSocketClass` | `CFSocket.c` FAIL: `#include <sys/ioctl.h>`; neither `machorun/sdk` nor the FE sysroot carries it (`cf_shims.sh` has `ioctl_darwin_requests.h`, not `ioctl.h`). Named in `cfobjc-fail.txt`. |
| 177 | ICU C APIs (`u_*`, `ucal_*`, `ucnv_*`, `ucol_*`, `ucurr_*`, `udat_*`, `udatpg_*`, `udtitvfmt_*`, `uenum_*`, `ufieldpositer_*`, `ulistfmt_*`, `uloc*`, `unum_*`, `unumsys_*`, `uregex_*`, `ureldatefmt_*`, `uset_*`, `utrans_*`, `UCNV_*`, `uameasfmt_*`) | The 16 ICU TUs *compile* against `swift-foundation-icu` headers. The harness does not link libicu, so those C APIs stay undefined. Headers-without-a-library is a named gap, not a missing `.o`. |
| 7 | `NXFindBestFatArch`, `NXGetLocalArchInfo`, `getsectbynamefromheader_64`, `getsegbyname`, `dlopen_preflight`, `mach_vm_region`, `vm_purgable_control` | Mach-O / dyld / VM SPI this `libSystem` does not export. (`_NSGetMachExecuteHeader` and `dyld_image_path_containing_address` are exported since machorun PR #67 and are no longer stubbed — measured on the x86 box at main 2c017e08.) |
| 5 | `fprintf_l`, `strncasecmp_l`, `strtol_l`, `strtoll_l`, `strtoul_l` | xlocale `*_l` / `fprintf_l` not in this `libSystem` (`strtod_l` is, since PR #67). |
| 3 | `_CFThreadSetName`, `pthread_attr_set_qos_class_np`, `qos_class_main` | Darwin thread / QoS SPI. `_CFThreadSetName` lives in CFPlatform.c's Swift-gated tail (`patch_cf_objc.py` records why that block cannot be admitted wholesale). |
| 1 | `OBJC_CLASS_$_NSMutableArray` (data) | Test fixture class. See `nsmutablearray-stub.md`. |
| 1 | `kCFRunLoopDefaultMode` (data) | Defined by `CFRunLoop.c`, which does not compile. |

Object-set pin (both arches, recipe `cfobjc.1` + ICU):

- PASS: `cfobjc-pass.txt` (80) — census `pass-79.txt` plus `CFUtilities` (fail-3's incomplete `struct proc_bsdshortinfo` compiles on this sysroot)
- FAIL: `cfobjc-fail.txt` — `CFRunLoop`, `CFSocket` only
- EMPTY: `cfobjc-empty.txt` — the four Windows/resource-fork TUs the census drops

Without ICU headers the recipe used to exit 0 with 64 objects (`CFString.c`
`#include <_foundation_unicode/uchar.h>` fails) and the harness stubbed
`CFStringCreateWithBytes`. That is the x86 143-stub failure. ICU is now
required, not optional.
