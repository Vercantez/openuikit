/* swiftcorepatch.c -- symbols the sysroot libswiftCore .tbd advertises (Xcode
 * 6.2.1 SDK) that the staged iOS-simulator libswiftCore.dylib runtime does not
 * export (version skew). Built into an UMBRELLA libswiftCore.dylib that defines
 * these and LC_REEXPORT_DYLIBs the real sim libswiftCore (libswiftCore.real.dylib).
 * Same mechanism as the libSystem / libc++ umbrellas (docs/RUNTIME.md sec 4).
 *
 * _stdlib_isOSVersionAtLeast[OrVariantVersion]: the compiler emits calls to
 * these for the availability checks inlined from the stdlib (no `#available`
 * appears in the slice source). They take Builtin.Word version components and
 * return Builtin.Int1. Our target is arm64-apple-macos11 and the runtime is
 * newer than anything the stdlib gates on, so every gated feature IS available:
 * return 1. Extra args are ignored (arm64 callee-ignores-surplus). */

/* _stdlib_isOSVersionAtLeastOrVariantVersion(Bi1, Bw,Bw,Bw,Bw,Bw,Bw) -> Bi1 */
int mr_isOSVerOrVariant(void)
    asm("_$ss042_stdlib_isOSVersionAtLeastOrVariantVersiondE0yBi1_Bw_BwBwBwBwBwtF");
int mr_isOSVerOrVariant(void) { return 1; }

/* _stdlib_isOSVersionAtLeast(Bw,Bw,Bw) -> Bi1 (the plain, non-zippered form) */
int mr_isOSVer(void)
    asm("_$ss26_stdlib_isOSVersionAtLeastyBi1_Bw_BwBwtF");
int mr_isOSVer(void) { return 1; }
