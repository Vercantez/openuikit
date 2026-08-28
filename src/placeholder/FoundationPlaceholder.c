/* FoundationPlaceholder.c -- NOT Foundation. An intentionally EMPTY dylib that
 * occupies /System/Library/Frameworks/Foundation.framework/Foundation in the
 * guest root.
 *
 * WHY IT EXISTS. Four of the staged Swift overlay dylibs are iOS-SIMULATOR
 * builds and carry an LC_LOAD_DYLIB on Apple's Foundation framework:
 *
 *     libswift_Builtin_float      libswift_RegexParser
 *     libswiftSynchronization     libswift_StringProcessing
 *
 * machorun refuses to load a guest whose dylib graph names a file that is not
 * there, so the load stops before main. Measured (2026-08-28, dyld_info
 * -fixups over all 12 staged overlays, 2,858 binds total):
 *
 *     binds attributed to Foundation ................ 0 of 2,858
 *     binds attributed to CoreFoundation ............ 0 of 2,858
 *
 * ALL FOUR declare the dependency and NONE of them binds a single symbol
 * through it -- ld64 keeps an LC_LOAD_DYLIB for a framework the driver named
 * on the command line whether or not anything used it. So the dependency is
 * real as a load-command and empty as a fact, and an empty file satisfies it
 * exactly.
 *
 * WHY IT EXPORTS NOTHING, AND WHY THAT IS THE SAFETY PROPERTY. This project is
 * BUILDING Foundation. A placeholder sitting at Foundation's canonical path is
 * precisely the shadowing hazard that has bitten this stack before (a
 * definition in the wrong image beating the real one). A dylib that exports
 * zero usable symbols CANNOT shadow anything: there is nothing for a binder to
 * choose. The one symbol below is in a reserved name nobody will ever
 * reference; it exists so that `nm` on the file at that path IDENTIFIES it as
 * the placeholder, which is what a gate can check.
 *
 * HOW IT FAILS, AND IT FAILS LOUDLY. These are two-level-namespace images, so
 * if anything ever does bind a real Foundation symbol through this slot the
 * loader stops at load time with "symbol not found in Foundation" and names
 * the symbol. There is deliberately no stub here that could return a plausible
 * value -- nothing is stubbed, so nothing can quietly succeed.
 *
 * WHAT IT IS NOT. It is not the port's Foundation and must never be mistaken
 * for it. When the real Foundation is built and installed, this file's slot is
 * what it replaces, and the check in scripts/build_foundation_placeholder.sh
 * is what tells the two apart.
 */

/* The fingerprint. Exported on purpose: `nm -g` on the file at Foundation's
 * path must be able to say "this is the placeholder" in one line. */
const char machorun_foundation_placeholder[] =
    "machorun placeholder: NOT Foundation, exports nothing, satisfies "
    "LC_LOAD_DYLIB only";
