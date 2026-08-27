// swiftcorepatch.c -- the stdlib entry points our COMPILER emits and the
// STAGED RUNTIME does not have.
//
// This is a structural mismatch, not a one-off: swiftc here is 6.2.x, while
// libswiftCore.dylib is Apple's shipped simulator runtime from an older
// toolchain (docs/RUNTIME.md §4). Anything the newer compiler emits a direct
// call to, the older runtime may simply lack. Expect this file to grow, and
// keep each entry documented with what emits it.
//
// THE SYSROOT DOES NOT WARN YOU. libswiftCore.tbd ADVERTISES
// _stdlib_isOSVersionAtLeastOrVariantVersion, so the link is clean and the
// failure is deferred to load time in the guest -- the same .tbd-disagrees-with-
// dylib class as pthread_main_np, but inverted (there the .tbd advertised too
// little; here it advertises too much).
//
// ---- _stdlib_isOSVersionAtLeastOrVariantVersion ----------------------------
// EMITTED BY: swift_task_deinitOnExecutorMainActorBackDeploy, the
// back-deployment thunk the compiler generates for a @MainActor-ISOLATED
// deinit. ~/uikit gained those when M15 put the UI classes under
// `-default-isolation MainActor`, which is why a build that had been loading
// for weeks stopped loading with no change on this side.
//
// The thunk asks "is the OS new enough to have swift_task_deinitOnExecutor?"
// and calls it if so. That function IS present here (libswift_Concurrency.dylib
// exports it), so the only thing missing is the question, not the answer.
//
// FORWARDS TO the 3-argument _stdlib_isOSVersionAtLeast, which this very dylib
// already exports. That is exactly what Apple's implementation does off
// macCatalyst: the "variant" triple describes the iOS-on-macOS variant of a
// zippered binary, and nothing here is zippered. Discarding it is the correct
// answer for this target, not a shortcut.
//
// ABI: a top-level Swift func with no self, no error and six Builtin.Word
// parameters returning Builtin.Int1 uses x0-x5 and returns in w0 -- identical
// to the C convention, so a plain C function is a valid definition.

#include <stdbool.h>

typedef unsigned long swift_word;

// Swift._stdlib_isOSVersionAtLeast(Builtin.Word, Builtin.Word, Builtin.Word) -> Builtin.Int1
extern bool mr_stdlib_isOSVersionAtLeast(swift_word major,
                                         swift_word minor,
                                         swift_word patch)
    __asm__("_$ss26_stdlib_isOSVersionAtLeastyBi1_Bw_BwBwtF");

// Swift._stdlib_isOSVersionAtLeastOrVariantVersion(...) -> Builtin.Int1
bool mr_stdlib_isOSVersionAtLeastOrVariantVersion(swift_word major,
                                                  swift_word minor,
                                                  swift_word patch,
                                                  swift_word variantMajor,
                                                  swift_word variantMinor,
                                                  swift_word variantPatch)
    __asm__("_$ss042_stdlib_isOSVersionAtLeastOrVariantVersiondE0yBi1_Bw_BwBwBwBwBwtF");

bool mr_stdlib_isOSVersionAtLeastOrVariantVersion(swift_word major,
                                                  swift_word minor,
                                                  swift_word patch,
                                                  swift_word variantMajor,
                                                  swift_word variantMinor,
                                                  swift_word variantPatch) {
    (void)variantMajor;
    (void)variantMinor;
    (void)variantPatch;
    return mr_stdlib_isOSVersionAtLeast(major, minor, patch);
}
